# trash-d

[![License](https://img.shields.io/github/license/rushsteve1/trash-d)](https://github.com/rushsteve1/trash-d/blob/main/LICENSE)
[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/rushsteve1/trash-d/D)](https://github.com/rushsteve1/trash-d/actions)
[![GitHub last commit (branch)](https://img.shields.io/github/last-commit/rushsteve1/trash-d/main)](https://github.com/rushsteve1/trash-d/commits/main)
[![GitHub tag (latest SemVer pre-release)](https://img.shields.io/github/v/tag/rushsteve1/trash-d?label=version)](https://github.com/rushsteve1/trash-d/releases)
[![Lines of code](https://img.shields.io/tokei/lines/github/rushsteve1/trash-d)](https://github.com/rushsteve1/trash-d/pulse)

A near drop-in replacement for `rm` that uses the
[FreeDesktop trash bin](https://specifications.freedesktop.org/trash-spec/trashspec-latest.html).
Written in the [D programming language](https://dlang.org/)
using only D's Phobos standard library, and can be compiled with any recent D
compiler. This includes GCC, so `trash-d` should run on any *NIX platform that
GCC supports.

**ONLY LINUX AND BSD ARE CURRENTLY SUPPORTED!**

Windows won't work at all, and MacOS probably won't either. Any POSIX and
FreeDesktop compliant system should work fine. For rarer *NIXs like Solaris or
AIX, you're on your own though. PRs for expanding support are very welcome!

You can install a pre-built statically-linked version (`x86_64-linux`) from the
[GitHub releases page](https://github.com/rushsteve1/trash-d/releases)

I gave a brief informal talk about this project and D at
[DoomConf 2021](https://doomconf.netlify.app/)
(recording is a bit messed up and only has half my talk) you can see also
[the slides here](https://doomconf.netlify.app/aug-2021/rushsteve1/trash-d).
I later re-wrote and updated/expanded on the presentation as
[a blog post](https://repo.rushsteve1.us/wiki?name=Developing+trash-d).

There are also several [posts on the D forums](https://forum.dlang.org/search?q=&exact=trash-d&newthread=y) about `trash-d`, if you want to give those a read.

### Installing

Simply drop the `trash` binary somewhere on your `$PATH` such as
`$HOME/.local/bin`, or use the provided DEB and RPM packages.

Optionally set `alias rm=trash` in your shell config to replace usages of `rm`
with `trash-d`.

Alternatively if there is a package for your OS should probably use that.

[![Packaging status](https://repology.org/badge/vertical-allrepos/trash-d.svg)](https://repology.org/project/trash-d/versions)

## Usage

Using `trash-d` is the same as most other command line utilities, and
intentionally very similar to `rm`.

See the [manual for more information](./MANUAL.md).

## Building

`trash-d` can be built using any D compiler, but it uses Dub and DMD by default.
You may need to adapt the build scripts, but the code should be completely
portable.

You can build it with Dub using `dub build` and run tests with `dub test`.

CMake build files can be generated using `dub generate cmake`.

### Using Rake

`trash-d` uses Ruby and Rake for it's build tooling. These are technically
optional and are not required to actually build the project, but make things
easier. Use `rake -T` to list all the available tasks.

To install all Ruby dependencies use
```sh
gem install --no-format-executable rake ronn-ng fpm
```

Ruby is required to build the manual page from the markdown file
using [Ronn-ng](https://github.com/apjanke/ronn-ng)
and can easily be built with `rake manpage`.
You may also need the `ruby-devel` and `rpmbuild` system packages.
Install these from your distro's package manager.

## Contributing

Contributions welcome! Please come help me clean up my D code, and otherwise
make `trash-d` more useful!

In particular help with packaging `trash-d` for various distros
and expanding support for other operating systems would be greatly appreciated!

However keep in mind that this is a simple tool with a simple job, so it's never
going to do *that* much.

Patches are also accepted via email if that's more your jam,
see [Contact below](#Contact) for more info.

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
- https://github.com/theimpossibleastronaut/rmw/
- https://github.com/alphapapa/rubbish.py
- https://github.com/kaelzhang/shell-safe-rm
- https://github.com/nateshmbhat/rm-trash
- https://github.com/PhrozenByte/rmtrash
- https://github.com/icyphox/crap

Unlike many of these, `trash-d` does not require an interpreter like Bash or
Python, so is more easily portable to new systems.

## Contact

You can email me at <mailto:rushsteve1@rushsteve1.us> or open an issue here on
GitHub if you need to reach me for whatever reason.

We do not have a mailing list or anything of that sort, but there is an
[ATOM feed of releases](https://github.com/rushsteve1/trash-d/releases.atom).
