/**
The runner function which dispatches to the correct operations based on the
CLI flags
*/

/*
See Also:
- https://dlang.org/
- https://specifications.freedesktop.org/trash-spec/trashspec-latest.html
*/

module trash.run;

import trash.opts : OPTS, parseOpts;
import trash.opers;
import trash.util : createMissingFolders, err, log, prompt;
import trash.ver : COPY_TEXT, VER_TEXT;

import std.file : FileException;
import std.stdio : writefln;
import std.string : startsWith;

/**
Given the remaining string arguments and the global `OPTS` struct, runs the
given commands. In other words, this function wraps around all the real
operations and acts as a secondary entrypoint that `main()` can `try`.
*/
@safe int runCommands(string[] args) {
	// Print the version number and return
	if (OPTS.ver) {
		writefln("\033[1m%s\033[0m\n\n%s", VER_TEXT, COPY_TEXT);
		return 0;
	}

	// Create missing folders if needed
	createMissingFolders();

	// Handle listing files in trash bin
	if (OPTS.list) {
		list();
		return 0;
	}

	// Handle listing out orphans
	if (OPTS.orphans) {
		orphans();
		return 0;
	}

	// Handle restoring trash files
	if (OPTS.restore)
		return restoreOrDel(OPTS.restore, false);

	// Handle deleting a file
	if (OPTS.del)
		return restoreOrDel(OPTS.del, true);

	// Handle emptying the trash
	if (OPTS.empty) {
		empty();
		return 0;
	}

	// Remove the first argument, ie the program name
	// Then make sure at least 1 file was specified
	args = args[1 .. $];
	if (args.length < 1) {
		err("missing operand");
		return 1;
	}

	// Prompt if deleting more than 3 things, or deleting recursively
	// This could probably be smarter, but I like it this way
	// because it will prompt more often.
	if (OPTS.interact_once && (args.length > 3 || OPTS.recursive)) {
		if (!prompt("remove %d arguments?", args.length)) {
			return 0;
		}
	}

	int ret = 0;
	// Loop through the args, trashing each of them in turn
	foreach (string path; args) {
		// wrap each argument in a try block,
		// so that failing any one does not stop execution.
		try {
			// If the path exists, delete trash the file
			// Handle the force --rm flag
			const int res = trashOrRm(path);
			if (res > 0)
				ret = 1;
		} catch (FileException e) {
			err(e.message());
			ret = 1;
		}
	}

	// Hooray, we made it all the way to the end!
	return ret;
}
