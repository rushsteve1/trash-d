/*
  Helper utility functions to perform various common operations
*/

import cli : OPTS;

import core.stdc.errno : EXDEV;
import std.stdio : stderr, stdin, writef;
import std.file;
import std.format : format;
import std.string : strip, toLower;
import std.path : buildNormalizedPath;

/**
   Prints a formatted error message to stderr with the program name at the
   beginning
*/
void err(Char, A...)(in Char[] fmt, A args) {
    stderr.writefln("%s: " ~ fmt, OPTS.prog_name, args);
}

/**
   Same as `err()` but only prints if `OPTS.verbose` is true
*/
void log(Char, A...)(in Char[] fmt, A args) {
    if (OPTS.verbose) {
        err("log: " ~ fmt, args);
    }
}

/**
   Same as `err()` but only prints if `OPTS.force` is false
*/
int ferr(Char, A...)(in Char[] fmt, A args) {
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

        if (src.isFile) {
            src.copy(tgt);
            src.remove();
	} else if (src.isDir) {
	    foreach(string name; src.dirEntries(SpanMode.shallow)) {
                name.renameOrCopy(buildNormalizedPath(tgt, name));
	    }
	    src.rmdir();
	} else {
	    err("path was neither file or directory");
	}
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
