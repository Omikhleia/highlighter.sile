std = "min+sile"
include_files = {
  "**/*.lua",
  "sile.in",
  "*.rockspec",
  ".busted",
  ".luacheckrc"
}
exclude_files = {
  "benchmark-*",
  "compare-*",
  "sile-*",
  "lua_modules",
  ".lua",
  ".luarocks",
  ".install"
}
globals = {
  -- acceptable as SILE has the necessary compatibility shims:
  -- pl.utils.unpack provides extra functionality and nil handling
  -- but our modules shouldn't be using that anyway.
  "table.unpack"
}
files["**/*_spec.lua"] = {
  std = "+busted"
}
files["lua-libraries"] = {
  -- matter of taste and not harmful
  ignore = {
    "211", -- unused function / unused variable
    "212/self", -- unused argument self
    "412", --variable was previously defined as an argument
  }
}
max_line_length = false
ignore = {
  "581", -- operator order warning doesn't account for custom table metamethods
  "212/self", -- unused argument self: counterproductive warning in methods
}
-- vim: ft=lua
