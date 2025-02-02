rockspec_format = "3.0"
package = "highlighter.sile"
version = "dev-1"
source = {
  url = "git+https://github.com/Omikhleia/highlighter.sile.git",
}
description = {
  summary = "A code syntax higlighting package for the SILE typesetting system.",
  detailed = [[
    This package for the SILE typesetting system provides a code syntax highlighter
    for various programming languages.
  ]],
  homepage = "https://github.com/Omikhleia/highlighter.sile",
  license = "MIT",
}
dependencies = {
   "lua >= 5.1",
}
build = {
  type = "builtin",
  modules = {
    ["sile.packages.highlighter"] = "packages/highlighter/init.lua",
  },
  copy_directories = {
    "scintillua",
  },
}
