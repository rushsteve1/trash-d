/**
   The runner function which dispatches to the correct operations based on the
   CLI flags
*/

/*
  See Also:
  - https://dlang.org/
  - https://specifications.freedesktop.org/trash-spec/trashspec-latest.html
*/

import cli : OPTS, parseOpts;
import operations;
import util : createMissingFolders, err, log;
import ver : COPY_TEXT, VER_TEXT;

import std.stdio : writefln;
import std.string : startsWith;

/**
   Given the remaining string arguments and the global `OPTS` struct, runs the
   given commands. In other words, this function wraps around all the real
   operations and acts as a secondary entrypoint that `main()` can `try`.
*/
int runCommands(string[] args) {
    // Print the version number and return
    if (OPTS.ver) {
        writefln("\033[1m%s\033[0m\n\n%s", VER_TEXT, COPY_TEXT);
        return -1;
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
    OPTS.prog_name = args[0];
    args = args[1 .. $];
    if (args.length < 1) {
        err("missing operand");
        return 1;
    }

    // Loop through the args, trashing each of them in turn
    foreach (string path; args) {
        // Arguments that start with a dash were unknown args
        // that got passed through by getopt, so just ignore them
        if (path.startsWith('-')) {
            log("unknown option '%s'", path);
            continue;
        }

        // If the path exists, delete trash the file
        // Handle the force --rm flag
        int res;
        res = trashOrRm(path);
        if (res > 0)
            return res;
    }

    // Hooray, we made it all the way to the end!
    return 0;
}
