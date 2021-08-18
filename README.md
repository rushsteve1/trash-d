# trash-d

A near drop-in replacement for `rm` that uses the
[Freedesktop trash bin](https://specifications.freedesktop.org/trash-spec/trashspec-latest.html).
Written in the [D programming language](https://dlang.org/).

**ONLY LINUX AND BSD ARE SUPPORTED**
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

Alternatively you can build with GDC using `gdc source/trash.d source/app.d -o trash`.

## Contributing

Contributions welcome! Please come help me clean up my D code, and otherwise
make `trash-d` more useful!

In particular help with packaging `trash-d` for various distros and operating
systems would be greatly appreciated!

However keep in mind that this is a simple tool with a simple job, so it's never
going to do *that* much.

## License

`trash-d` is licensed under the terms of the [MIT License](./LICENSE).
You are free to use it for any purpose under the terms of that license.
