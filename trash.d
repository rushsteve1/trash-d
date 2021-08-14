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

import std.getopt;
import std.process : environment;
import std.stdio;
import std.file;
import std.path;
import std.random;
import std.format;
import std.datetime.systime;
import std.string;
import std.conv : to;
import core.memory;
import core.stdc.errno : EXDEV;

/*
  ===============================================================================
                              Structs & Constants
  ===============================================================================
*/

/// trash-d is versioned sequentially starting at 1
const int VER = 5;

struct Opts {
    string prog_name = "trash";
    bool recursive;
    bool verbose;
    bool interactive;
    bool force;
    bool list;
    bool empty;
    bool rm;
    string restore;
    string del;
    string trash_dir;
    bool ver;

    @property string info_dir() const {
        return trash_dir ~ "/info";
    }

    @property string files_dir() const {
        return trash_dir ~ "/files";
    }

    @property string dirsize_file() const {
        return trash_dir ~ "/directorysizes";
    }
}

// The parsed CLI options are stored here on a global struct
static Opts OPTS;

struct TrashFile {
    const string info_fstr = "[Trash Info]\nPath=%s\nDeletionDate=%s";
    string file_name;
    string orig_path;
    SysTime deletion_date;

    this(in string n) {
        file_name = n;

        if (exists(info_path)) {
            parseInfo();
        }
    }

    this(in string p, in SysTime now) {
        orig_path = p.absolutePath();
        file_name = orig_path.baseName().chompPrefix(".");

        // If a file with the same name exists in the trash,
        // generate a random 4-digit numeric suffix
        if (file_path.exists()) {
            file_name = file_name ~ "-" ~ to!string(uniform(1000, 9999));
        }

        deletion_date = now;
    }

    @property string file_path() const {
        return OPTS.files_dir ~ "/" ~ file_name;
    }

    @property string info_path() const {
        return OPTS.info_dir ~ "/" ~ file_name ~ ".trashinfo";
    }

    void parseInfo() {
        log("parsing trashinfo: %s", info_path);
        string text = info_path.readText();
        string d;
        formattedRead(text, info_fstr, orig_path, d);
        deletion_date = SysTime.fromISOExtString(d);
    }

    @property string infoString() const {
        return format(info_fstr, orig_path, deletion_date.toISOExtString());
    }

    string toString() const {
        return format("%s\t%s\t%s", file_name, orig_path, deletion_date.toSimpleString());
    }
}

/*
  ===============================================================================
                                Helper Functions
  ===============================================================================
*/

pragma(inline)
void err(Char, A...)(in Char[] fmt, A args) {
    stderr.writefln("%s: " ~ fmt, OPTS.prog_name, args);
}

pragma(inline):
void log(Char, A...)(in Char[] fmt, A args) {
    if (OPTS.verbose) {
        err(fmt, args);
    }
}

bool prompt(Char, A...)(in Char[] fmt, A args) {
    writef("Are you sure you want to %s? [y/N] ", format(fmt, args));
    string input = stdin.readln().strip().toLower();
    return input == "y";
}

bool iprompt(Char, A...)(in Char[] fmt, A args) {
    if (OPTS.interactive && !OPTS.force) {
        const bool res = prompt(fmt, args);
        if (!res) {
            return false;
        }
    }
    return true;
}

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
}

void renameOrCopy(in string src, in string tgt) {
    try {
        src.rename(tgt);
    } catch (FileException e) {
        if (e.errno != EXDEV) throw e;

        src.copy(tgt);
        src.remove();
    }
}

/*
  ===============================================================================
                               CLI Flag Handlers
  ===============================================================================
*/

int trash(string path) {
    if (!OPTS.recursive && path.isDir()) {
        err("cannot remove '%s': Is a directory", path);
        return 1;
    }

    if (!iprompt("move %s' to the trash bin", path))
        return 0;

    const auto now = Clock.currTime();
    const auto tfile = TrashFile(path, now);

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

int rm(string path) {
    if (!OPTS.recursive && path.isDir()) {
        err("cannot remove '%s': Is a directory", path);
        return 1;
    }

    if (!iprompt("move %s' to the trash bin", path))
        return 0;

    path = path.absolutePath();

    log("deleting: %s", path);

    path.remove();

    return 0;
}

void empty() {
    if (prompt("empty the trash bin") || OPTS.force) {
        try {
            log("deleting folder: %s", OPTS.files_dir);
            OPTS.files_dir.rmdirRecurse();
        } catch (FileException e) {
            log("folder did not exist, ignoring");
        }

        try {
            log("deleting folder: %s", OPTS.info_dir);
            OPTS.info_dir.rmdirRecurse();
        } catch (FileException e) {
            log("folder did not exist, ignoring");
        }

        try {
            log("deleting file: %s", OPTS.dirsize_file);
            OPTS.dirsize_file.remove();
        } catch (FileException e) {
            log("folder did not exist, ignoring");
        }

        writeln("Trash emptied");
    }
}

void list() {
    auto entries = OPTS.info_dir.dirEntries(SpanMode.shallow);

    if (entries.empty) {
        writeln("Trash bin is empty");
        return;
    }

    foreach (DirEntry entry; entries) {
        writeln(TrashFile(entry.name.baseName().stripExtension()));
    }

}

int del(string name) {
    if (!iprompt("delete the file '%s'", name)) return 0;

    const auto tfile = TrashFile(name);

    if (!exists(tfile.file_path)) {
        err("cannot delete '%s': No such file or directory", name);
        return 1;
    }

    log("deleting: %s", name);

    tfile.file_path.remove();
    if (tfile.info_path.exists())
        tfile.info_path.remove();

    return 0;
}

int restore(string name) {
    if (! iprompt("restore the file '%s'", name)) return 0;

    const auto tfile = TrashFile(name);

    if (!exists(tfile.file_path)) {
        err("cannot restore '%s': No such file or directory", name);
        return 1;
    }

    if (!exists(tfile.info_path)) {
        err("cannot restore '%s': No trashinfo file", name);
        return 1;
    }

    log("restoring: %s", name);

    tfile.file_path.renameOrCopy(tfile.orig_path);
    tfile.info_path.remove();

    return 0;
}

/*
  ===============================================================================
                                  CLI Parsing
  ===============================================================================
*/

int parseOpts(ref string[] args) {
    // Hang on the the unparsed argument length
    const ulong arglen = args.length;

    // Parse CLI options using D's getopt
    GetoptResult helpInfo;
    try {
        helpInfo = getopt(args,// Allow flags to be bundled like -rf
                std.getopt.config.bundling,// Pass through flags that weren't understood
                // These will get ignored later, but it adds graceful rm compatibility
                std.getopt.config.passThrough,
                // The // at the end of each line keeps dfmt from merging lines
                "recursive|r", "Delete directories and their contents", &OPTS.recursive, //
                "verbose|v", "Print more information", &OPTS.verbose, //
                "interactive|i", "Ask before each deletion", &OPTS.interactive, //
                "force|f", "Ignore non-existant and don't prompt", &OPTS.force, //
                "empty", "Empty the trash bin", &OPTS.empty, //
                "delete", "Delete a file from the trash", &OPTS.del, //
                "list", "List out the files in the trash", &OPTS.list, //
                "restore", "Restore a file from the trash", &OPTS.restore, //
                "rm", "Escape hatch to permanently delete a file", &OPTS.rm, //
                "version", "Output the version and exit", &OPTS.ver, //
                );
    } catch (GetOptException e) {
        err(e.message());
    }

    // Handle requests for help text
    // This includes when no arguments are given
    if (helpInfo.helpWanted || arglen < 2) {
        defaultGetoptPrinter("trash [OPTION]... [FILE]...\nA near drop-in replacement for rm that uses the trash bin",
                helpInfo.options);
        if (arglen < 2)
            return 1;
        return -1;
    }

    // Print the version number and return
    // This is here so that the program quits out on --version quickly
    if (OPTS.ver) {
        writeln(VER);
        return -1;
    }

    // Get the correct XDG directory
    string data_home = environment.get("XDG_DATA_HOME");
    if (data_home is null) {
        data_home = expandTilde("~/.local/share");
    }

    // Set the trash dir option
    OPTS.trash_dir = absolutePath(data_home ~ "/Trash");
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

int runCommands(string[] args) {
    // Handle emptying the trash
    if (OPTS.empty) {
        empty();
        return 0;
    }

    // Create missing folders if needed
    createMissingFolders();

    // Handle listing files in trash bin
    if (OPTS.list) {
        list();
        return 0;
    }

    // Handle deleting a file
    if (OPTS.del)
        return del(OPTS.del);

    // Handle restoring trash files
    if (OPTS.restore)
        return restore(OPTS.restore);

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
        if (path.exists()) {

            // Handle the force --rm flag
            int res;
            if (OPTS.rm) {
                res = rm(path);
            } else {
                res = trash(path);
            }
            if (res > 0) return res;
        } else if (!OPTS.force) {
            err("cannot remove '%s': No such file or directory", path);
            return 1;
        }
    }

    // Hooray, we made it all the way to the end!
    return 0;
}

/*
  ===============================================================================
                                Main Entrypoint
  ===============================================================================
*/

int main(string[] args) {
    // Due to the short-lived CLI nature of this program,
    // I have opted to disable the garbage collector.
    // This should squeeze out a bit of performance,
    // while ultimately not affecting memory usage very much
    GC.disable();

    // Parse the command line options
    const int res = parseOpts(args);
    switch (res) {
        case 0: break;
        case -1: return 0;
        default: return res;
    }

    // Everything is wrapped in a single outermost try/catch block
    // to make error handling much simpler.
    try {
        return runCommands(args);
    } catch (FileException e) {
        err(e.message());
        return 1;
    }
}
