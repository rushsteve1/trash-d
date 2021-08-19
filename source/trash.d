/*
  trash-d
  A near drop-in replacement for rm that uses the trash bin
  https://github.com/rushsteve1/trash-d
*/

/*
  MIT License

  Copyright (c) 2021 Steven vanZyl

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
*/

/*
  See Also:
  - https://dlang.org/
  - https://specifications.freedesktop.org/trash-spec/trashspec-latest.html
*/

import std.getopt;
import std.process : environment;
import std.stdio;
import std.file;
import std.path;
import std.random;
import std.format;
import std.datetime.systime : Clock, SysTime;
import std.string;
import std.outbuffer : OutBuffer;
import std.algorithm : map, maxElement;
import std.range : array, chain;
import core.stdc.errno : EXDEV;
import core.time : hnsecs;

/*
  ===============================================================================
                              Structs & Constants
  ===============================================================================
*/

/// trash-d is versioned sequentially starting at 1
const int VER = 10;
const string VER_NAME = "Jetstream Sam";
const string VER_TEXT = format("trash-d version %s '%s'", VER, VER_NAME);
const string COPY_TEXT = "Copyright (C) 2021 Steven vanZyl.
License MIT <https://mit-license.org/>.
Fork on GitHub <https://github.com/rushsteve1/trash-d>

This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Written by Steven vanZyl <rushsteve1@rushsteve1.us>.";

/**
   The parsed command line options are stored in this struct
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
        return trash_dir.chainPath("info").array();
    }

    /// The path to the files directory
    @property @safe string files_dir() const nothrow {
        return trash_dir.chainPath("files").array();
    }

    /// The path to the directorysizes file
    @property @safe string dirsize_file() const nothrow {
        return trash_dir.chainPath("directorysizes").array();
    }
}

/// The parsed CLI options are stored here on a global `Opts` struct
static Opts OPTS;

/**
   This struct wraps data about a single file in the trash (or that is being
   moved to the trash).
   It provides facilities for getting related info about a file and for
   generating and parsing its `.trashinfo` file
*/
struct TrashFile {
    /// Format string used to parse and format the `.trashinfo` files
    const string info_fstr = "[Trash Info]\nPath=%s\nDeletionDate=%s";
    /// The base name of this file
    string file_name;
    /// The absolute original path of this file
    string orig_path;
    /// The date and time this file was deleted
    SysTime deletion_date;

    /**
       When given one string the constructor assumes that this is a file that is
       already in the trash. It will then parse the matching `.trashinfo` file.
    */
    this(in string n) {
        file_name = n;

        if (exists(info_path)) {
            parseInfo();
        }
    }

    /**
       When given a string and a `SysTime` the constructor assumes that this is
       a file that is about to be added to the trash bin.
    */
    this(in string p, in SysTime now) {
        orig_path = p.absolutePath();
        file_name = orig_path.baseName().chompPrefix(".");

        // If a file with the same name exists in the trash,
        // generate a random 4-digit numeric suffix
        if (file_path.exists()) {
            file_name = format("%s-%s", file_name, uniform(1000, 9999));
        }

        deletion_date = now;
    }

    /// Path to the file in the trash bin
    @property @safe string file_path() const nothrow {
        return OPTS.files_dir.chainPath(file_name).array();
    }

    /// Path to the matching `.trashinfo` file
    @property @safe dstring info_path() const {
        return OPTS.info_dir.chainPath(file_name).chain(".trashinfo").array();
    }

    // TODO check for and report write protected files like RM does
    @property @safe attr_orig() const {
        assert(orig_path.exists());
        return orig_path.getAttributes();
    }

    @property @safe bool writeable() const {
        import core.sys.posix.sys.stat;

        return cast(bool)(attr_orig & S_IWUSR);
    }

    /// Parses the related `.trashinfo` file, pulling the info from it
    void parseInfo() {
        log("parsing trashinfo: %s", info_path);
        string text = info_path.readText();
        string d;
        formattedRead(text, info_fstr, orig_path, d);
        deletion_date = SysTime.fromISOExtString(d);
    }

    /// Formats a `.trashinfo` for this file
    @property @safe string infoString() const {
        return format(info_fstr, orig_path, deletion_date.toISOExtString());
    }
}

/*
  ===============================================================================
                                Helper Functions
  ===============================================================================
*/

/**
   Prints a formatted error message to stderr with the program name at the
   beginning
*/
pragma(inline) void err(Char, A...)(in Char[] fmt, A args) {
    stderr.writefln("%s: " ~ fmt, OPTS.prog_name, args);
}

/**
   Same as `err()` but only prints if `OPTS.verbose` is true
*/
pragma(inline):
void log(Char, A...)(in Char[] fmt, A args) {
    if (OPTS.verbose) {
        err("log: " ~ fmt, args);
    }
}

pragma(inline) int ferr(Char, A...)(in Char[] fmt, A args) {
    if (OPTS.force) {
        log(fmt, args);
        return 0;
    } else {
        err(fmt, args);
        return 1;
    }
}

/**
   Prompts the user for a yes or no input, defaulting to no.
*/
bool prompt(Char, A...)(in Char[] fmt, A args) {
    writef("Are you sure you want to %s? [y/N] ", format(fmt, args));
    string input = stdin.readln().strip().toLower();
    return input == "y" || input == "yes";
}

/**
   Same as `prompt()` but only prompts if `OPTS.interactive` is true and
   `OPTS.force` is false
*/
bool iprompt(Char, A...)(in Char[] fmt, A args) {
    if (OPTS.interactive && !OPTS.force) {
        const bool res = prompt(fmt, args);
        if (!res) {
            return false;
        }
    }
    return true;
}

/**
   Creates the trash directory folders if they are missing
*/
void createMissingFolders() {
    if (!exists(OPTS.trash_dir)) {
        mkdir(OPTS.trash_dir);
        log("creating trash directory");
    }
    if (!exists(OPTS.info_dir)) {
        mkdir(OPTS.info_dir);
        log("creating trash info directory");
    }
    if (!exists(OPTS.files_dir)) {
        mkdir(OPTS.files_dir);
        log("creating trash file directory");
    }
    if (!exists(OPTS.dirsize_file)) {
        std.file.write(OPTS.dirsize_file, "");
        log("creating directorysizes file");
    }
}

/**
   Attempts to rename a file `src` to `tgt`, but if that fails with `EXDEV` then
   the `src` and `tgt` paths are on different devices and cannot be renamed
   across. In that case perform a copy then remove
*/
void renameOrCopy(in string src, in string tgt) {
    try {
        src.rename(tgt);
    } catch (FileException e) {
        if (e.errno != EXDEV)
            throw e;

        src.copy(tgt);
        src.remove();
    }
}

/**
   Is it OK to delete this folder (if it is one). This looks at `OPTS.recusive`
   and `OPTS.dir` and the status and contents of `path` to determine if the user
   wants the action to be allowable.
*/
bool dirOk(in string path) {
    if (!OPTS.recursive && path.isDir()) {
        if (OPTS.dir) {
            if (!path.dirEntries(SpanMode.shallow).empty) {
                err("cannot remove '%s': Directory not empty", path);
                return false;
            }
        } else {
            err("cannot remove '%s': Is a directory", path);
            return false;
        }
    }
    return true;
}

/*
  ===============================================================================
                               CLI Flag Handlers
  ===============================================================================
*/

/**
   Depending on the value of OPTS.rm this either sends the file/folder at the
   given path to the trash or permanently deletes it.
   This was originally 2 functions but they were overly similar
*/
int trashOrRm(in string path) {
    if (!exists(path)) {
        return ferr("cannot delete '%s': No such file or directory", path);
    }

    if (!path.dirOk())
        return 1;

    string fstr = (OPTS.rm) ? "move '%s' to the trash bin" : "permanently delete '%s'";
    if (!iprompt(fstr, path))
        return 0;

    // Get the current time without the fractional part
    auto now = Clock.currTime();
    now.fracSecs = hnsecs(0);
    const auto tfile = TrashFile(path, now);

    // Check if the file is writeable and prompt the user the same way rm does
    if (!tfile.writeable && !OPTS.force) {
        writef("%s: remove write-protected regular file '%s'? ", OPTS.prog_name, path);
        string input = stdin.readln().strip().toLower();
        if (input != "y" && input != "yes")
            return 0;
    }

    // If the --rm flag is given, act on that
    // Otherwise continue on with the regular trashing
    if (OPTS.rm) {
        log("deleting: %s", path);
        path.remove();
        return 0;
    }

    log("trashing: %s", tfile.orig_path);

    // Move the file to the trash files dir
    path.renameOrCopy(tfile.file_path);

    // Write the .trashinfo file
    tfile.info_path.append(tfile.infoString);

    if (tfile.file_path.isDir()) {
        const ulong size = tfile.file_path.getSize();
        OPTS.dirsize_file.append(format("%s %s %s", size, now.toUnixTime(), tfile.file_name));
    }

    return 0;
}

/**
   Given the `--empty` flag this deletes the trash folders.
   Always prompts the user first unless `--force` is given
*/
void empty() {
    // Only prompt the user if the --force flag wasn't given
    if (OPTS.force || prompt("empty the trash bin")) {
        log("deleting folder: %s", OPTS.files_dir);
        OPTS.files_dir.rmdirRecurse();

        log("deleting folder: %s", OPTS.info_dir);
        OPTS.info_dir.rmdirRecurse();

        log("deleting file: %s", OPTS.dirsize_file);
        OPTS.dirsize_file.remove();

        // Always print out that the trash bin was emptied
        writeln("Trash bin emptied");

        createMissingFolders();
    }
}

/**
   Prints out a files in the trash with their name, original path, and deletion
   date as a tab-separated table
*/
void list() {
    // The Freedesktop spec specifies that the files in the info folder, not the
    // files, folder defines what's in the trash bin.
    // This can lead to some odd cases, but --empty should handle them.
    auto entries = OPTS.info_dir.dirEntries(SpanMode.shallow);

    // If the trash is empty then say so
    if (entries.empty) {
        writeln("Trash bin is empty");
        return;
    }

    // Map the `DirEntry`s to `TrashFile`s
    auto tf = entries.map!(e => TrashFile(e.name.baseName().stripExtension())).array();

    // Calculate the maximum length of the name and path for formatting
    ulong maxname = tf.map!(t => t.file_name.length).maxElement();
    log("max name length: %s", maxname);

    ulong maxpath = tf.map!(t => t.orig_path.length).maxElement();
    log("max path length: %s", maxpath);

    // Write out the list with a header
    writefln("%-*s\t%-*s\t%s", maxname, "Name", maxpath, "Path", "Del. Date");
    foreach (TrashFile t; tf) {
        writefln("%-*s\t%-*s\t%s", maxname, t.file_name, maxpath, t.orig_path, t.deletion_date);
    }
}

/**
   Depending on the value of the `del` paramater this function either deletes a
   single file from the trash bin, or restores a file from the trash bin to its
   original path.
   This was originally 2 functions but they were overly similar
*/
int restoreOrDel(in string name, bool del) {
    // Make a string holding the name of the operation
    string opstr = (del) ? "permanently delete" : "restore";

    if (!iprompt("%s the file '%s'", opstr, name))
        return 0;

    const auto tfile = TrashFile(name);

    if (!exists(tfile.file_path)) {
        return ferr("cannot %s '%s': No such file or directory", opstr, name);
    }

    if (!exists(tfile.info_path)) {
        return ferr("cannot %s '%s': No trashinfo file", opstr, name);
    }

    log("%s : %s", opstr.chop() ~ "ing", name);

    // Make sure to warn the user when restoring over another file
    if (!del && tfile.orig_path.exists() && !OPTS.force) {
        if (!prompt("you want to overwrite the existing file at %s?", tfile.orig_path)) {
            return 0;
        }
    }

    // If del is on, delete otherwise restore
    if (del) {
        tfile.file_path.remove();
    } else {
        tfile.file_path.renameOrCopy(tfile.orig_path);
    }
    // Always remove the trashinfo file
    tfile.info_path.remove();

    return 0;
}

/*
  ===============================================================================
                                  CLI Parsing
  ===============================================================================
*/

/**
   Parses the command line options into the `OPTS` global struct using D's built-in `getopt` parser
*/
int parseOpts(ref string[] args) {
    // Hang on the the unparsed argument length
    const ulong arglen = args.length;

    // Always reset the global options at each call
    // This is mostly useful for testing
    // TODO this is funky, clean it up a bit
    Opts o;
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

    // Get the correct XDG directory
    string data_home = environment.get("XDG_DATA_HOME");
    if (data_home is null) {
        data_home = expandTilde("~/.local/share");
    }

    // Set the trash dir option
    OPTS.trash_dir = data_home.chainPath("Trash").asAbsolutePath().array();
    log("trash directory: %s", OPTS.trash_dir);

    // This function is a little special because it has a unique return code
    // -1 means "stop program and with status code 0"
    return 0;
}

/*
  ===============================================================================
                             CLI Commands Execution
  ===============================================================================
*/

/**
   Given the remaining string arguments and the global `OPTS` struct, runs the
   given commands. In other words, this function wraps around all the real
   operations and acts as a secondary entrypoint that `main()` can `try`.
*/
int runCommands(string[] args) {
    // Create missing folders if needed
    createMissingFolders();

    // Handle emptying the trash
    if (OPTS.empty) {
        empty();
        return 0;
    }

    // Handle listing files in trash bin
    if (OPTS.list) {
        list();
        return 0;
    }

    // Handle deleting a file
    if (OPTS.del)
        return restoreOrDel(OPTS.del, true);

    // Handle restoring trash files
    if (OPTS.restore)
        return restoreOrDel(OPTS.restore, false);

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
