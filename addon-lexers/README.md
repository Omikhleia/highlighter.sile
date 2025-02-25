Scintillua is normally used in text editors, where syntax highlighting can occur as you type.
This requires lexers to be context-free, so that they can be run on incomplete code.

The lexers in this directory, however, implement some context-sensitive rules, and only work on complete code.

That's the main reason for the separate directory, and these lexers not being upstreamed to Scintillua.

For the type of problems that can arise in a Scintillua-based text editor, as the user types code on the fly,
see [this discussion](https://github.com/orbitalquark/scintillua/pull/144#pullrequestreview-2635010023).
