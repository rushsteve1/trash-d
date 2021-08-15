# trash-d

A near drop-in replacement for `rm` that uses the
[Freedesktop trash bin](https://specifications.freedesktop.org/trash-spec/trashspec-latest.html).
Written in the [D programming language](https://dlang.org/).

**DOES NOT WORK ON WINDOWS** and there are no plans for support.
Should work on any POSIX system with a D compiler.

You can install a pre-built version from the
[GitHub releases page](https://github.com/rushsteve1/trash-d/releases)

I gave a brief informal talk about this project and D at
[DoomConf 2021](https://doomconf.netlify.app/)
which also serves as documentation
[slides here here](https://doomconf.netlify.app/rushsteve1/trash-d)

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

You can build it with Dub using `dub build`.
Or with GDC using `gdc trash.d -o trash`.

## Contributing

Contributions welcome! Please come help me clean up my D code, and otherwise
make `trash-d` more useful!

However keep in mind that this is a simple tool with a simple job, so it's never
going to do *that* much.

## License

`trash-d` is licensed under the terms of the [MIT License](./LICENSE).
You are free to use it for any purpose under the terms of that license.
