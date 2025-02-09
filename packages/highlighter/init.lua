--
-- A syntax highlighter package for SILE, based on Scintillua.
-- Compatible with SILE standard distribution.
-- Compatible with the resilient collection (style-aware).
--
-- Copyright (c) 2025, Omikhleia, Didier Willis
-- License: MIT
--
-- Scintillua itself is:
--   Copyright (c) 2007-2025 Mitchell
--   License: MIT
--
-- Message to the knowledgeable readers in the SILE ecosystem:
-- "Where is the horse gone? Where the rider? Where the giver of treasure?"
--
local base = require("packages.base")

-- PACKAGE PATH HACKING
--
-- Scintillua assumes lpeg is available, which is our case with SILE.
-- But it also needs fancy stuff to find and load its lexers, and we don't want
-- SILE to be polluted with it.
-- So we need to temporarily hack the package.path to make it work.
-- It's a little dumb and probably overkill, but it's fun, right?
-- So here we go, first, create a Lua loader with loadkit...
local loadkit = require("loadkit")
local loader = loadkit.make_loader("lua")
-- Then use it to resolve the path to the lexer module, wherever bundled...
local lexer_path = pl.path.dirname(loader("scintillua.lexers.lexer"))
-- Now we can assume all lexers are in the same directory...
-- But SILE's package API defines its own package object, so we need to
-- do all this magic before the package definition, in order to play with
-- the standard 'package' table.
-- You are having as much fun as I am, right?
lexer_path = lexer_path .. "/?.lua"
local function hackRequirePathForScintillua(callback)
  local old = package.path
  package.path = lexer_path
  local ret = callback()
  package.path = old
  return ret
end

-- THEMING (DEFAULT)

-- N.B. "standard" Scintillua tags are:
--   'whitespace', 'comment', 'string', 'number', 'keyword', 'identifier',
--   'operator', 'error', 'preprocessor', 'constant', 'variable', 'function',
--   'class', 'type', 'label', 'regex', 'embedded', 'function.builtin',
--   'constant.builtin', 'function.method', 'tag', 'attribute',
--   'variable.builtin', 'heading', 'bold', 'italic', 'underline', 'code',
--   'link', 'reference', 'annotation', 'list'
-- Some lexers may have more...
-- So the theme below (loosely based on some Eclipse theme) is a bit ad-hoc,
-- and may not cover all cases.
local theme = {
  -- whitespace -- No style for whitespace
  comment = { color =  '#8E908C', font = { style = 'italic' } },
  string = { color =  '#3F7F5F' },
  number = { color =  '#116644' },
  keyword = { color =  '#7F0055' },
  identifier = { color =  '#3F009B' },
  operator = { color =  '#3E999F' },
  error = { color =  '#8B0000' },
  preprocessor = { color =  '#4D4D4C' },
  constant = { color =  '#116644' },
  variable = { color =  '#0000C0' },
  ['function'] = { color =  '#4271AE' },
  class = { color =  '#C99000' },
  ['type'] = { color =  '#C99000' },
  label = { color =  '#2A00FF' },
  regex = { color =  '#0000C0' },
  embedded = { color =  '#4271AE' },
  ['function.builtin'] = { color =  '#4271AE' },
  ['constant.builtin'] = { color =  '#F5871F' },
  ['function.method'] = { color =  '#4271AE' },
  tag = { color =  '#7F0055' },
  attribute = { color =  '#0000C0' },
  ['variable.builtin'] = { color =  '#C82829' },
  heading = { color =  '#2A00FF' },
  bold = { font = { weight = 400 } },
  italic = { font = { style = 'italic' } },
  underline = { decoration = { line = 'underline' } },
  -- code -- No style for code, as we are in a code block?
  link = { decoration = { line = 'underline'} },
  reference  = { decoration = { line = 'underline' } },
  -- annotation -- No style for annotation?
  list = { color =  '#116644' },
  -- Special cases
  --- For latex
  command = { color =  '#7F0055' },
  ['command.section'] = { color =  '#C99000' },
  ['environment'] = { color =  '#C99000' },
  ['environment.math'] = { color =  '#116644' },
  --- For diff
  addition = {
    color =  '#C99000',
    decoration = {
      line = 'mark',
      color = '#FFDE8A',
    }
  },
  deletion = {
    color =  '#8B0000',
    decoration = {
      line = 'mark',
      color = '#F6B2B2',
    }
  },
  change = {
    color =  '#0000C0',
    decoration = {
      line = 'mark',
      color = '#B2D8FF',
    }
  },
  --- For CSS
  property = { color =  '#0000C0' },
}

-- Put that in a SILE 'scratch' variable, so users in a non-resilient context
-- can still access it for their own theme overrides.
-- Yeah, such scratch variables are bad.
-- Yet, we're playing nice beyond the call of duty, because we are resilient.
SILE.scratch.highlighter = SILE.scratch.highlighter or { theme = theme }

-- SILE PACKAGE

local package = pl.class(base)
package._name = "highlighter"

function package:_init (_)
  base._init(self)
  self:loadAltPackage("resilient.verbatim", "verbatim")

  -- Names of available lexers.
  self._hasLexer = {}
  self._lexernames = hackRequirePathForScintillua(function()
    -- Scintillua assumes lfs is available, which is our case with SILE.
    -- But we need to hack the package.path to make it work where the lexers
    -- are, and not whatever the current directory is...
    local lexer = require('lexer')
    local names = lexer.names()
    -- Note: the Scintillua API says it returns a list of names, but it actually
    -- returns a table with the names as 'true' values:
    -- { "name1", "name2", ... name1 = true, name2 = true, ... }).
    -- Since this is not documented, we do not rely on it, and just extract the
    -- keys from the list.
    -- The extra work is negligible, and it makes the code more robust if the
    -- undocumented internals changes...
    -- You still have fun, right?
    for _, v in ipairs(names) do
      self._hasLexer[v] = true
    end
  end)
  -- Compatibility with the resilient styling paradigm.
  if self.class.hasStyle then
    self:registerStyles()
  end
end

--- Load a package with a resilient variant, if we are in a resilient context.
function package:loadAltPackage (resilientpack, legacypack)
  -- If our class is styled, we want to use the resilient style-aware variant.
  -- Otherwise, we use the legacy package.
  -- Pretty lame, but heh, we try to play fair with the standard SILE
  -- distribution.
  -- Actually in a resilient context, the compatibility layer would enforce
  -- the use of the resilient variant anywaut, but with a ugly warning.
  -- More fun on the way, right?
  if self.class.hasStyle then
    SU.debug("highlighter", "Loading style-aware package", resilientpack)
    self:loadPackage(resilientpack)
  else
    SU.debug("highlighter", "Loading legacy package", legacypack)
    self:loadPackage(legacypack)
  end
end

function package:_lexerForLanguage (name)
  return self._hasLexer[name]
end

function package:_applyStyleIfDefined (token, snippet)
  local styleCommand
  -- Use the resilient styling paradigm if available.
  -- Otherwise, use the default theme colors and fonts,
  -- and ignore other properties.
  if self.class.hasStyle then
    local style = "highlight-" .. token
    if self.class:hasStyle(style) then
      styleCommand = SU.ast.createCommand("style:apply", { name = style }, snippet)
    end
  else
    local rule = theme[token]
    if rule then
      if rule.color then
        if rule.font then
          snippet = SU.ast.createCommand("font", rule.font, snippet)
        end
        styleCommand = SU.ast.createCommand("color", { color = rule.color }, snippet)
      elseif rule.font then
        styleCommand = SU.ast.createCommand("font", rule.font, snippet)
      end
    end
  end
  return styleCommand
end

function package:_findAndApplyClosestStyle(token, snippet)
  -- token might be name1.name2.name3...
  -- Try to find the more specific style first.
  local styleCommand = self:_applyStyleIfDefined(token, snippet)
  if not styleCommand then
    -- Remove the last part
    local subtoken = token:gsub("%.[^.]*$", "")
    -- If we removed something, try again with the shorter token
    if subtoken ~= token then
      return self:_findAndApplyClosestStyle(subtoken, snippet)
    end
  end
  return styleCommand
end

function package:registerRawHandlers ()
  self.class:registerRawHandler("highlight", function(options, content)
    local code = content[1]
    local lang = options.language
    -- HACK: Quick and dirty compatibility with the markdown.sile collection.
    -- In Markdown, one can write:
    --   ```rust
    --   code
    --   ```
    -- In Djot, while the same works, one could also possibly write:
    --   {#id .dot render=false}
    --   ```
    --   code
    --   ```
    -- Djot is still an experimental in-progress format.
    -- Whether the above is legit or not is a matter of interpretation.
    -- But for divs (:::), the "word" on the opening line is currently
    -- a class, so there's discussion on making it a "tag" instead.
    --
    -- TL;DR.
    -- Our markdown.sile collection wants to support both cases.
    -- So it pushes the language as a class.
    local languages = options.class and pl.stringx.split(options.class, " ") or {}
    if lang then
      table.insert(languages, 1, lang)
    end
    if #languages == 0 then
      -- No language specified, just print the code as is.
      SILE.call("verbatim", {}, { code })
      return
    end

    -- Find a lexer for the language(s)
    local ret = hackRequirePathForScintillua(function()
      local lexer = require('lexer')
      local found
      for _, v in ipairs(languages) do
        if v ~= "highlight" and self:_lexerForLanguage(v) then
          found = v
          break
        end
      end
      if not found then
        SU.debug("highlighter", "No lexer found for language", options.class)
        return {}
      end
      local fname = found
      local lex = lexer.load(fname)
      return { lex:lex(code), fname }
    end)
    local tokens, language = table.unpack(ret)
    if not tokens then
      -- No lexer found, just print the code as is.
      SILE.call("verbatim", {}, { code })
      return
    end
    -- Now we have tokens, we can style them.
    local spans = {}
    local last = 1
    local nostyle = {}
    for i = 1, #tokens, 2 do
      local token = tokens[i]
      local pos = tokens[i+1]
      local snippet = code:sub(last, pos-1)
      local styled = self:_findAndApplyClosestStyle(token, snippet)
      if styled then
        table.insert(
          spans,
          styled
        )
      else
        -- For debug, track tokens not styled:
        -- Most of the time this would be a whitespace token,
        -- though some lexers may have other tokens that are not styled yet.
        nostyle[token] = true
        table.insert(
          spans,
          luautf8.char(0x200B) .. snippet
          -- HACK
          -- We insert a zero-width space to prevent the
          -- line from collapsing when containing a line-break.
          -- It seems SILE's typesetter still has something unclear here?
        )
      end
      last = pos
    end
    SILE.call("verbatim", {}, spans)
    if next(nostyle) then
      SU.debug(
        "highlighter",
        "Some tokens are not styled for language",
        language or "unknown",
        table.concat(pl.tablex.keys(nostyle), ", ") -- Slightly bad: computed even with no debug
      )
    end
  end)
end

function package:registerStyle (name, opts, styledef)
  return self.class:registerStyle(name, opts, styledef, self._name)
end

function package:registerStyles ()
  for token, style in pairs(theme) do
    self:registerStyle("highlight-" .. token, {}, style)
  end
end

package.documentation =[[\begin{document}
The \autodoc:package{highlighter} package is a code syntax highlighter for SILE, based on Scintillua.
It is compatible with the standard SILE distribution and the (style-aware) resilient collection of classes and packages.

The package provides a raw handler \code{highlight} for syntax-highlighting code blocks in your documents.
Parameter \autodoc:parameter{language} is used to specify the language of the code block.
Without it, or for an unsupported language, the code block is displayed as is.
For easier compatibility with Markdown, you can also use the \autodoc:parameter{class} parameter to specify a space-separated list of classes, and the first one that matches a supported language is used.

When used in a style-aware context, the package registers a set of character styles \code{highlight-⟨token⟩} for most token types recognized by Scintillua.
You can then customize your document style file and modify anything you want, from colors to fonts and decorations, and more.

In a non-style-aware context, the package uses a default theme for highlighting, and only honors the color and font properties.

\end{document}]]

return package
