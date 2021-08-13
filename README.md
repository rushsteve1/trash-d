# trash-d
A near drop-in replacement for rm that uses the
[Freedesktop trash bin](https://specifications.freedesktop.org/trash-spec/trashspec-latest.html).
Written in the [D programming language](https://dlang.org/).

Should work on any POSIX system with a D compiler.

**DOES NOT WORK ON WINDOWS** and there are no plans for support.

You can install a pre-built version from the
[GitHub releases page](https://github.com/rushsteve1/trash-d/releases)

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
going to do *too* much.

## License

`trash-d` is licensed under the terms of the [MIT License](./LICENSE).
You are free to use it for any purpose under the terms of that license.

## Known Limitations

- You can't trash a file across a filesystem border. This can lead to issues
  when trashing from `tmpfs` or removable drives.
  Contributions towards fixing this are welcome!
