# trash-d
A near drop-in replacement for rm that uses the
[Freedesktop trash bin](https://specifications.freedesktop.org/trash-spec/trashspec-latest.html).
Written in the [D programming language](https://dlang.org/).

Should work on any POSIX system with a D compiler.

**DOES NOT WORK ON WINDOWS** and there are no plans for support.

You can install a pre-built version from the
[GitHub releases page](https://github.com/rushsteve1/trash-d/releases)

## Building

`trash-d` can be built using any D compiler, and uses GDC by default.
It can be built with the [Makefile](./Makefile) using `make trash`.
To build with debug symbols and less optimization use `make debug`.
If you want the built executable stripped, use `make strip`.

Install to `/usr/bin` (or an overriden `DESTDIR`) with `make install`.

## Contributing

Contributions welcome! Please come help me clean up my D code,
and otherwise make `trash-d` more useful!

## License

`trash-d` is licensed under the terms of the [MIT License](./LICENSE).
