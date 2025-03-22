# highlighter.sile

[![License](https://img.shields.io/github/license/Omikhleia/highlighter.sile?label=License)](LICENSE)
[![Luacheck](https://img.shields.io/github/actions/workflow/status/Omikhleia/highlighter.sile/luacheck.yml?branch=main&label=Luacheck&logo=Lua)](https://github.com/Omikhleia/highlighter.sile/actions?workflow=Luacheck)
[![Luarocks](https://img.shields.io/luarocks/v/Omikhleia/highlighter.sile?label=Luarocks&logo=Lua)](https://luarocks.org/modules/Omikhleia/highlighter.sile)

This package for the [SILE](https://github.com/sile-typesetter/sile) typesetting system provides a code “syntax highlighter”.

It's a simple wrapper around the [Scintillua](https://github.com/orbitalquark/scintillua) syntax highlighting library, providing a SILE package to use it.

![Syntax highlighted code](highlighter.png "Syntax highlighted code")

The package works both with SILE's standard distribution and with the [**resilient.sile**](https://github.com/Omikhleia/resilient.sile) collection of classes and packages.
In the latter case, it subscribes to the resilient styling paradigm, allowing for fine-grained control over the appearance of the highlighted code.

## Installation

This package require SILE v0.15 or upper.

Installation relies on the **luarocks** package manager.

To install the latest version, you may use the provided “rockspec”:

```
luarocks install highlighter.sile
```

(Refer to the SILE manual for more detailed 3rd-party package installation information.)

## Usage

Examples are provided in the [examples](./examples) folder.

The in-code package documentation may also be useful.

A readable version of the documentation is included in the User Manual for the [resilient.sile](https://github.com/Omikhleia/resilient.sile) collection of classes and packages.

## Supported languages

The package supports all languages for which a Scintillua lexer is available, i.e. more that 150 languages, including:

`actionscript`, `ada`, `antlr`, `apdl`, `apl`, `applescript`, `asm`, `asp`, `autohotkey`, `autoit`, `awk`,
`bash`, `batch`, `bibtex`, `boo`,
`c`, `caml`, `chuck`, `clojure`, `cmake`, `coffeescript`, `container`, `context`, `cpp`, `crystal`, `csharp`, `css`, `cuda`,
`d`, `dart`, `desktop`, `diff`, `django`, `djot`, `dockerfile`, `dot`,
`eiffel`, `elixir`, `elm`, `erlang`,
`factor`, `fantom`, `faust`, `fennel`, `fish`, `forth`, `fortran`, `fsharp`, `fstab`,
`gap`, `gemini`, `gettext`, `gherkin`, `git-rebase`, `gleam`, `glsl`, `gnuplot`, `go`, `groovy`, `gtkrc`,
`hare`, `haskell`, `html`,
`icon`, `idl`, `inform`, `ini`, `io_lang`,
`java`, `javascript`, `jq`, `json`, `jsp`, `julia`,
`latex`, `ledger`, `less`, `lilypond`, `lisp`, `litcoffee`, `logtalk`, `lua`,
`makefile`, `markdown`, `matlab`, `mediawiki`, `meson`, `moonscript`, `myrddin`,
`nemerle`, `networkd`, `nim`, `nix`, `nsis`, `null`,
`objeck`, `objective_c`, `output`,
`pascal`, `perl`, `php`, `pico8`, `pike`, `pkgbuild`, `pony`, `powershell`, `prolog`, `props`, `protobuf`, `ps`, `pure`, `python`,
`r`, `rails`, `rc`, `reason`, `rebol`, `rest`, `rexx`, `rhtml`, `routeros`, `rpmspec`, `ruby`, `rust`,
`sass`, `scala`, `scheme`, `smalltalk`, `sml`, `snobol4`, `spin`, `sql`, `strace`, `systemd`,
`taskpaper`, `tcl`, `tex`, `texinfo`, `text`, `toml`, `troff`, `txt2tags`, `typescript`,
`vala`, `vb`, `vcard`, `verilog`, `vhdl`,
`wsf`,
`xml`, `xs`, `xtend`,
`yaml`, `zig`.

It also supports the following "add-on lexers" (which are not included in the Scintillua distribution as the current implementation of their grammar is not context-free, and thus not suitable for text editors where the user can type code on the fly):
- `sil` (SILE's custom SIL "TeX-like flavor" language).

If your favorite language is not supported, and you are a Lua programmer with some experience using LPeg, you may want to contribute a lexer to the Scintillua project, before suggesting it here.
It's a cool project, and the maintainers are very friendly and helpful.

## License

All SILE-related code and samples in this repository are released under the MIT License, (c) 2025, Omikhleia.

The syntax highlighting support (as a Git submodule) is [Scintillua](https://github.com/orbitalquark/scintillua), which is released under the MIT License, (c) 2007-2025, Mitchell.
