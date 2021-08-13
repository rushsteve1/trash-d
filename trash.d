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

// trash-d is versioned sequentially starting at 1
const int VER = 3;

struct Opts {
    bool recursive;
    bool verbose;
    bool interactive;
    bool force;
    bool list;
    bool empty;
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

struct TrashInfo {
    const string fstring = "[Trash Info]\nPath=%s\nDeletionDate=%s";
    string path;
    SysTime deletion_date;

    this(string p, SysTime d) {
        path = p;
        deletion_date = d;
    }

    this(string text) {
        string d;
        formattedRead(text, fstring, path, d);
        deletion_date = SysTime.fromISOExtString(d);
    }

    string toString() const {
        return format(fstring, path, deletion_date.toISOExtString());
    }
}

static Opts OPTS;

pragma(inline):
void log(string s) {
    if (OPTS.verbose) {
        stderr.writeln(s);
    }
}

pragma(inline):
void log(string s, string p) {
    if (OPTS.verbose) {
        stderr.writeln(s, p);
    }
}

int main(string[] args) {
    auto arglen = args.length;

    // Parse CLI options
    GetoptResult helpInfo;
    try {
        helpInfo = getopt(args, std.getopt.config.bundling,
            "recursive|r", "Delete directories and their contents", &OPTS.recursive,
            "verbose|v", "Print more information", &OPTS.verbose,
            "interactive|i", "Ask before each deletion", &OPTS.interactive,
            "force|f", "Ignore non-existant and don't prompt", &OPTS.force,
            "empty", "Empty the trash bin", &OPTS.empty,
            "delete", "Delete a file from the trash", &OPTS.del,
            "list", "List out the files in the trash", &OPTS.list,
            "restore", "Restore a file from the trash", &OPTS.restore,
            "version", "Output the version and exit", &OPTS.ver,
        );
    } catch (GetOptException e) {
        stderr.writeln(e);
    }

    // Handle requests for help text
    if (helpInfo.helpWanted || arglen < 2) {
        defaultGetoptPrinter("trash [OPTION]... [FILE]...\nA near drop-in replacement for rm that uses the trash bin",
                helpInfo.options);
        return 0;
    }

    // Print the version number and return
    if (OPTS.ver) {
        writeln(VER);
        return 0;
    }

    // Get the correct XDG directory
    string data_home = environment.get("XDG_DATA_HOME");
    if (data_home is null) {
        data_home = expandTilde("~/.local/share");
    }

    // Set the trash dir option
    OPTS.trash_dir = absolutePath(data_home ~ "/Trash");
    log("Trash directory: ", OPTS.trash_dir);

    // Handle emptying the trash
    if (OPTS.empty) {
        empty();
        return 0;
    }

    // Create missing folders if needed
    if (!exists(OPTS.trash_dir)) {
        mkdir(OPTS.trash_dir);
        log("Creating trash directory");
    }
    if (!exists(OPTS.info_dir)) {
        mkdir(OPTS.info_dir);
        log("Creating trash info directory");
    }
    if (!exists(OPTS.files_dir)) {
        mkdir(OPTS.files_dir);
        log("Creating trash file directory");
    }

    if (OPTS.list) {
        list();
        return 0;
    }

    // Handle deleting a file
    if (OPTS.del) {
        return del(OPTS.del);
    }

    // Handle restoring trash files
    if (OPTS.restore) {
        return restore(OPTS.restore);
    }

    // Remove the first argument, ie the program name
    // Then make sure at least 1 file was specified
    args = args[1 .. $];
    if (args.length < 1) {
        stderr.writeln("trash: missing operand");
        return 1;
    }

    // Loop through the args, trashing each of them in turn
    foreach (string path; args) {
        if (exists(path)) {
            int ret = trash(path);
            if (ret > 0) {
                return ret;
            }
        } else if (!OPTS.force) {
            stderr.writefln("trash: cannot remove '%s': No such file or directory", path);
            return 1;
        }
    }

    // Hooray, we made it all the way to the end!
    return 0;
}

bool prompt(string text) {
    writef("Are you sure you want to %s? [y/N] ", text);
    string input = stdin.readln().strip().toLower();
    return input == "y";
}

int trash(string path) {
    if (!OPTS.recursive && path.isDir()) {
        stderr.writefln("trash: cannot remove '%s': Is a directory", path);
        return 1;
    }

    if (OPTS.interactive && !OPTS.force) {
        bool res = prompt(format("delete '%s'", path));
        if (!res) {
            return 0;
        }
    }

    path = path.absolutePath();

    string name = path.baseName().chompPrefix(".");
    string file = OPTS.files_dir ~ "/" ~ name;

    // If a file with the same name exists in the trash,
    // generate a random suffix
    if (file.exists()) {
        name = name ~ "-" ~ to!string(uniform(1000, 9999));
        file = OPTS.files_dir ~ "/" ~ name;
    }

    // Get the info directory and current time
    string info = OPTS.info_dir ~ "/" ~ name ~ ".trashinfo";
    auto now = Clock.currTime();
    TrashInfo tinfo = TrashInfo(path, now);

    // Move the file to the trash files dir
    path.rename(file);

    // Writ the .trashinfo file
    info.append(tinfo.toString());

    if (file.isDir()) {
        auto size = file.getSize();
        OPTS.dirsize_file.append(format("%s %s %s", size, now.toUnixTime(), name));
    }

    return 0;
}

void empty() {
    bool res = prompt("empty the trash bin");
    if (res || OPTS.force) {
        try {
            log("Deleting folder: ", OPTS.files_dir);
            OPTS.files_dir.rmdirRecurse();
        } catch (FileException e) {
            log("Folder did not exist, ignoring");
        }

        try {
            log("Deleting folder: ", OPTS.info_dir);
            OPTS.info_dir.rmdirRecurse();
        } catch (FileException e) {
            log("Folder did not exist, ignoring");
        }

        try {
            log("Deleting file: ", OPTS.dirsize_file);
            OPTS.dirsize_file.remove();
        } catch (FileException e) {
            log("Folder did not exist, ignoring");
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
        TrashInfo tinfo = TrashInfo(entry.readText());
        writefln("%s\t%s\t%s", entry.name.baseName().stripExtension(),
                tinfo.path, tinfo.deletion_date.toSimpleString());
    }

}

int del(string name) {
    if (OPTS.interactive) {
        bool res = prompt(format("delete the file '%s'", name));
        if (!res) {
            return 0;
        }
    }

    string file = OPTS.files_dir ~ "/" ~ name;
    string info = OPTS.info_dir ~ "/" ~ name ~ ".trashinfo";

    if (!exists(file)) {
        stderr.writefln("trash: cannot delete '%s': No such file or directory", name);
        return 1;
    }

    log("Deleting: ", name);

    file.remove();
    info.exists() && info.remove();

    return 0;
}

int restore(string name) {
    if (OPTS.interactive) {
        bool res = prompt(format("restore the file '%s'", name));
        if (!res) {
            return 0;
        }
    }

    string file = OPTS.files_dir ~ "/" ~ name;
    string info = OPTS.info_dir ~ "/" ~ name ~ ".trashinfo";

    if (!exists(file)) {
        stderr.writefln("trash: cannot restore '%s': No such file or directory", name);
        return 1;
    }

    if (!exists(info)) {
        stderr.writefln("trash: cannot restore '%s': No trashinfo file", name);
        return 1;
    }

    log("Restoring: ", name);

    TrashInfo tinfo = TrashInfo(info.readText());
    file.rename(tinfo.path);
    info.remove();

    return 0;
}
