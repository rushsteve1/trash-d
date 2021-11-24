# trash-d

![GitHub](https://img.shields.io/github/license/rushsteve1/trash-d)
![GitHub Workflow Status](https://img.shields.io/github/workflow/status/rushsteve1/trash-d/D)
![GitHub last commit (branch)](https://img.shields.io/github/last-commit/rushsteve1/trash-d/main)
![GitHub tag (latest SemVer pre-release)](https://img.shields.io/github/v/tag/rushsteve1/trash-d?label=version)
![Lines of code](https://img.shields.io/tokei/lines/github/rushsteve1/trash-d)

A near drop-in replacement for `rm` that uses the
[FreeDesktop trash bin](https://specifications.freedesktop.org/trash-spec/trashspec-latest.html).
Written in the [D programming language](https://dlang.org/)
using only D's Phobos standard library.

**ONLY LINUX AND BSD ARE CURRENTLY SUPPORTED!**

Windows won't work at all, and MacOS probably won't either.
Any POSIX and FreeDesktop compliant system should work fine.
PRs for expanding support are very welcome!

You can install a pre-built version (`x86_64-linux-gnu`) from the
  * [ ] [GitHub releases page](https://github.com/rushsteve1/trash-d/releases)

I gave a brief informal talk about this project and D at
[DoomConf 2021](https://doomconf.netlify.app/)
(recording is a bit messed up and only has half my talk) you can see also
[the slides here](https://doomconf.netlify.app/rushsteve1/trash-d)

## Building

`trash-d` can be built using any D compiler, but it uses Dub and DMD by default.
You may need to adapt the build scripts, but the code should be completely
portable.

You can build it with Dub using `dub build` and run tests with `dub test`.

CMake build files can be generated using `dub generate cmake`.

### Installing

Simply drop the `trash` binary somewhere on your `$PATH` such as
`$HOME/.local/bin` or use the provided DEB and RPM packages.

Optionally set `alias rm=trash` in your shell config to replace usages of `rm`
with `trash-d`.

## Usage

Using `trash-d` is the same as most other command line utilities, and
intentionally very similar to `rm`.

See the [manual for more information](./MANUAL.md).


### `rm` compatibility

One of `trash-d`'s primary goals is near compatibility with the standard `rm`
tool.The keyword here is "near". The goal is not exact flag-for-flag
compatibility with `rm`, but you should be able to `alias rm=trash` and not
notice the difference.

Because of this, `trash-d` will silently ignore unknown options.
Be warned that this may be subject to change as `trash-d`'s compatibility
with `rm` increases.

## Contributing

Contributions welcome! Please come help me clean up my D code, and otherwise
make `trash-d` more useful!

In particular help with packaging `trash-d` for various distros
and expanding support for other operating systems would be greatly appreciated!

However keep in mind that this is a simple tool with a simple job, so it's never
going to do *that* much.

## Version Numbers

Versions of `trash-d` are numbered sequentially with a bump every time I change
some functionality. Consider every change to be a breaking change, and be
happily surprised when it's not!
I have a bad habit of bumping the number with one commit, only to immediately
bump it again before tagging a release. So the releases might have some gaps.
Sorry about that...

Version names are changed whenever something major has changed. Don't treat
these like actual version indicators, they're just something fun.

## License

`trash-d` is licensed under the terms of the [MIT License](./LICENSE).
You are free to use it for any purpose under the terms of that license.

## Similar Projects

- https://github.com/andreafrancia/trash-cli
- https://github.com/sindresorhus/trash
- https://github.com/alphapapa/rubbish.py
