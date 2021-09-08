/**
  CLI flag parsing and structure using D's getopt implementation
*/

import ver : COPY_TEXT, VER, VER_NAME, VER_TEXT;
import run : OPTS;
import util : log, err;

import std.getopt;
import std.outbuffer : OutBuffer;
import std.path : absolutePath, buildPath, expandTilde;
import std.process : environment;
import std.stdio : writefln;

/**
   The parsed command line options. Each field maps to a command line option or
   environment variable
*/
struct Opts {
    /// The program's name, `args[0]`. Not a CLI option
    string prog_name = "trash";

    /// The directory to use for trash. Not a CLI option
    string trash_dir;

    // ===== Options from rm =====
    /// Should empty directories be deleted
    bool dir;
    /// Should folder contents should be deleted
    bool recursive;
    /// Print additional logging
    bool verbose;
    /// Ask before doing things
    bool interactive;
    /// Should things be forced
    bool force;
    /// Print the version
    bool ver;

    // ===== Custom Options ====
    /// List out the files in the trash bin
    bool list;
    /// Empty the trash bin
    bool empty;
    /// Actually delete instead of moving to trash
    bool rm;
    /// Restore the given file
    string restore;
    /// Delete the given file from the trash
    string del;

    /// The path to the info directory
    @property @safe string info_dir() const nothrow {
        return trash_dir.buildPath("info");
    }

    /// The path to the files directory
    @property @safe string files_dir() const nothrow {
        return trash_dir.buildPath("files");
    }

    /// The path to the directorysizes file
    @property @safe string dirsize_file() const nothrow {
        return trash_dir.buildPath("directorysizes");
    }
}

/**
   Parses the command line options into the `OPTS` global struct using D's built-in `getopt` parser
*/
int parseOpts(ref string[] args) {
    // Hang on the the unparsed argument length
    const ulong arglen = args.length;

    // Always reset the global options at each call
    // This is mostly useful for testing
    // TODO this is funky, clean it up a bit
    const Opts o;
    OPTS = o;

    // Parse CLI options using D's getopt
    GetoptResult helpInfo;
    try {
        // dfmt off
        helpInfo = getopt(args,
                // Allow flags to be bundled like -rf
                std.getopt.config.bundling,
                // Pass through flags that weren't understood
                // These will get ignored later, but it adds graceful rm compatibility
                std.getopt.config.passThrough,
                "dir|d", "Remove empty directories.", &OPTS.dir,
                "recursive|r", "Delete directories and their contents.", &OPTS.recursive,
                "verbose|v", "Print more information.", &OPTS.verbose,
                "interactive|i", "Ask before each deletion.", &OPTS.interactive,
                "force|f", "Don't prompt and ignore errors.", &OPTS.force,
                "version", "Output the version and exit.", &OPTS.ver,

                "empty", "Empty the trash bin.", &OPTS.empty,
                "delete", "Delete a file from the trash.", &OPTS.del,
                "list", "List out the files in the trash.", &OPTS.list,
                "restore", "Restore a file from the trash.", &OPTS.restore,
                "rm", "Escape hatch to permanently delete a file.", &OPTS.rm,
        );
        // dfmt on
    } catch (GetOptException e) {
        err(e.message());
    }

    // Handle requests for help text
    // This includes when no arguments are given
    if (helpInfo.helpWanted || arglen < 2) {
        // trash-d changes the formatting of the help text to be much nicer
        string text = "Usage: \033[1mtrash [OPTIONS...] [FILES...]\033[0m\n";
        OutBuffer buf = new OutBuffer();
        defaultGetoptFormatter(buf, text, helpInfo.options, "\t%*s  %*s\t%*s%s\x0a");
        writefln("%s\n\n%s\n%s", VER_TEXT, buf, COPY_TEXT);

        if (arglen < 2)
            return 1;
        return -1;
    }

    // Print the version number and return
    // This is here so that the program quits out on --version quickly
    if (OPTS.ver) {
        writefln("\033[1m%s\033[0m\n\n%s", VER_TEXT, COPY_TEXT);
        return -1;
    }

    OPTS.trash_dir = environment.get("TRASH_D_DIR");
    if (OPTS.trash_dir is null) {
        // Get the correct XDG directory
        string data_home = environment.get("XDG_DATA_HOME");
        if (data_home is null) {
            data_home = expandTilde("~/.local/share");
        } else {
            // Set the trash dir option
            OPTS.trash_dir = data_home.buildPath("Trash").absolutePath();
            log("trash directory: %s", OPTS.trash_dir);
        }
    }

    // This function is a little special because it has a unique return code
    // -1 means "stop program and with status code 0"
    return 0;
}
