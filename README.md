# trash-d

A near drop-in replacement for `rm` that uses the
[Freedesktop trash bin](https://specifications.freedesktop.org/trash-spec/trashspec-latest.html).
Written in the [D programming language](https://dlang.org/).

**ONLY LINUX AND BSD ARE SUPPORTED!**
Windows won't work at all, and MacOS probably won't either.
There are no plans for support of either platform.
Any POSIX and Freedesktop compliant system should work fine.

You can install a pre-built version (`x86_64-linux-gnu`) from the
[GitHub releases page](https://github.com/rushsteve1/trash-d/releases)

I gave a brief informal talk about this project and D at
[DoomConf 2021](https://doomconf.netlify.app/)
you can see
[the slides here](https://doomconf.netlify.app/rushsteve1/trash-d)

## `rm` compatibility

One of `trash-d`'s primary goals is near compatibility with the standard `rm`
tool.The keyword here is "near". The goal is not exact flag-for-flag
compatibility with `rm`, but you should be able to `alias rm=trash` and not
notice the difference.

Because of this, `trash-d` will silently ignore unknown options.

## Building

`trash-d` can be built using any D compiler, but it uses Dub and DMD by default.
You may need to adapt the build scripts, but the code should be completely
portable.

You can build it with Dub using `dub build` and run tests with `dub test`.

CMake build files can be generated using `dub generate cmake`.

### Installing

Simply drop the `trash` binary somewhere on your `$PATH` such as `$HOME/.local/bin`.

Optionally set `alias rm=trash` in your shell config to replace usages of `rm`
with `trash-d`.

## Usage

Using `trash-d` is the same as most other command line utilities, and
intentionally very similar to `rm`.

`trash [OPTIONS...] [FILES...]`

### Options & Flags

The options and flags are intended to mirror `rm`'s closely, with some
additional long options for the `trash-d` specific features.

- `-d`, `--dir` Remove empty directories.
- `-r`, `--recursive` Delete directories and their contents.
- `-v`, `--verbose` Print more information.
- `-i`, `--interactive` Ask before each deletion.
- `-f`, `--force` Don't prompt and ignore errors.
- `--version` Output the version and exit.
- `--empty` Empty the trash bin.
- `--delete FILE` Delete a file from the trash.
- `--list` List out the files in the trash.
- `--restore FILE` Restore a file from the trash.
- `--rm` Escape hatch to permanently delete a file.
- `-h`, `--help` This help information.


#### Option Precedence

The `--help`, `--version`, `--list`, `--restore`, `--delete`, and
`--empty` flags all cause the program to short-circuit and perform only that
operation and no others. Their precedence is in that order exactly, and is
intended to cause the least destruction.

Therefore the command `trash --empty --list` will list the trash bin and NOT
empty it.

**NOTE:** Before version 11 `trash-d` followed a slightly incorrect precedence
order.

## Contributing

Contributions welcome! Please come help me clean up my D code, and otherwise
make `trash-d` more useful!

In particular help with packaging `trash-d` for various distros and operating
systems would be greatly appreciated!

However keep in mind that this is a simple tool with a simple job, so it's never
going to do *that* much.

## Version Numbers

Versions of `trash-d` are numbered sequentially with a bump every time I change
some functionality. Consider every change to be a breaking change, and be
happily surprised when it's not!

Version names are changed whenever something major has changed. Don't treat
these like actual version indicators, they're just something fun.

## License

`trash-d` is licensed under the terms of the [MIT License](./LICENSE).
You are free to use it for any purpose under the terms of that license.
