--
-- A syntax highlighter package for SILE, based on Scintillua.
-- Compatible with SILE standard distribution.
-- Compatible with the resilient collection (style-aware).
--
-- Copyright (c) 2025, Didier Willis
-- License: MIT
--
-- Scintillua itself is:
--   Copyright (c) 2007-2025 Mitchell
--   License: MIT
--
-- Message to the knowledgeable readers in the ecosystem:
-- "Where is the horse gone? Where the rider? Where the giver of treasure?"
--
local base = require("packages.base")

-- PACKAGE PATH HACKING
--
-- Scintillua assumed lpeg is available, which is our case with SILE.
-- But it also needs fancy stuff to load its lexers....
-- And we don't want SILE to be polluted with this stuff.
-- So we need to temporarily hack the package.path to make it work.
-- It's a little dumb and probably overkill, but it's fun, right?
-- So here we go, first, create a Lua loader with loadkit...
local loadkit = require("loadkit")
local loader = loadkit.make_loader("lua")
-- Then Use it to resolve the path to the lexer module, wherever bundled...
local lexer_path = pl.path.dirname(loader("scintillua.lexers.lexer"))
-- Now we can assume all lexers are in the same directory...
-- But SILE's package stuff defines its own package object, so we need to
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
  -- whitespace = nil, -- No style for whitespace
  comment = '#8E908C',
  string = '#3F7F5F',
  number = '#116644',
  keyword = '#7F0055',
  identifier = '#3F009B',
  operator = '#3E999F',
  error = '#8B0000',
  preprocessor = '#4D4D4C',
  constant = '#116644',
  variable = '#0000C0',
  ['function'] = '#4271AE',
  class = '#C99000',
  ['type'] = '#C99000',
  label = '#2A00FF',
  regex = '#0000C0',
  embedded = '#4271AE',
  ['function.builtin'] = '#4271AE',
  ['constant.builtin'] = '#F5871F',
  ['function.method'] = '#4271AE',
  tag = '#7F0055',
  attribute = '#0000C0',
  ['variable.builtin'] = '#C82829',
  -- Special cases
  --- For latex
  command = '#7F0055',
  ['command.section'] = '#C99000',
  ['environment'] = '#C99000',
  ['environment.math'] = '#116644',
  --- For diff
  addition = '#C99000',
  deletion = '#8B0000',
  change = '#0000C0',
  --- For CSS
  property = '#0000C0',
}

-- Put that in a SILE 'scratch' variable, so users in a non-resilient context
-- can still access it for their own theming.
-- Yeah, such scratch variables are bad.
-- Yet, we're playing nice beyond the call of duty, because we are resilient.
SILE.scratch.highlighter = SILE.scratch.highlighter or { theme = theme }

-- SULE PACKAGE

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
    -- Compatibility with the resilient styling paradigm.
    if self.class.hasStyle then
      self:registerStyles()
    end
  end)

end

--- Load a package with a resilient variant, if we are in a resilient context.
function package:loadAltPackage (resilientpack, legacypack)
  -- If our class is styled, we want to use the resilient style-aware variant.
  -- Otherwise, we use the legacy package.
  -- Pretty lame, but heh, we try to play fair with the standard SILE
  -- distribution
  -- Actually in a resilient context, the compatibility layer would enforce
  -- the use of the resilient variant, but with a ugly warning.
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

function package:registerRawHandlers ()
  self.class:registerRawHandler("highlight", function(options, content)
    local code = content[1]
    local lang = options.language
    -- HACK: Quick and dirty compatibility with the markdown.sile collection.
    -- We'd rather do this in a more elegant way there.
    -- Not general: while { .highlight .rust } would work, or (in Djot)
    --   {.highlight}
    --   ```rust
    --   code
    --   ```
    -- This does not work for 'lua' as markdown.sile doesn't trigger
    -- the raw handler if the classes contain 'lua', but reverts to its
    -- own naive highlighting.
    -- Do one has to explicitly set { .highlight language="lua" }.
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
      local styleCommand
      -- Use the resilient styling paradigm if available.
      -- Otherwise, use the default theme colors.
      if self.class.hasStyle then
        local style = "highlight-" .. token
        if self.class:hasStyle(style) then
          styleCommand = SU.ast.createCommand("style:apply", { name = style }, snippet)
        end
      else
        local color = theme[token]
        if color then
          styleCommand = SU.ast.createCommand("color", { color = color }, snippet)
        end
      end
      if styleCommand then
        table.insert(
          spans,
          styleCommand
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
  for k, v in pairs(theme) do
    self:registerStyle("highlight-" .. k, {}, {
      color = v
    })
  end
end

package.documentation =[[\begin{document}
The \autodoc:package{highlighter} package is a code syntax highlighter for SILE, based on Scintillua.
It is compatible with the standard SILE distribution and the (style-aware) resilient collection of classes and packages.

The package provides a raw handler \code{highlight} for syntax-highlighting code blocks in your documents.
Parameter \autodoc:parameter{language} is used to specify the language of the code block.
Without it, or for an unsupported language, the code block is displayed as is.

When used in a style-aware context, the package registers a set of character styles \code{highlight-⟨token⟩} for each token type recognized by Scintillua.
You can then customize your document style file and modify anything you want, from colors to fonts and decorations.

In a non-style-aware context, the package uses a default theme for highlighting.

\end{document}]]

return package
