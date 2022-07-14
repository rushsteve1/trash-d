/**
   The various file operations that trash-d can perform
*/

module trash.opers;

import trash.opts : OPTS;
import trash.file : TrashFile;
import trash.util;

import core.time : hnsecs;
import std.algorithm;
import std.datetime.systime : Clock;
import std.conv : to;
import std.file;
import std.format : format;
import std.path : baseName, buildNormalizedPath, stripExtension;
import std.range : array;
import std.stdio;
import std.string;

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
        const bool confirmed = prompt("remove write-protected regular file '%s'", path);
        if (!confirmed)
            return 0;
    }

    // If the --rm flag is given, act on that
    // Otherwise continue on with the regular trashing
    if (OPTS.rm) {
        log("deleting: %s", path);
        if (path.isDir()) {
            path.rmdirRecurse();
        } else {
            path.remove();
        }
        return 0;
    }

    log("trashing: %s", tfile.orig_path);

    // Move the file to the trash files dir
    const bool res = path.renameOrCopy(tfile.file_path);
    if (!res)
        return 1;

    // Write the .trashinfo file
    tfile.info_path.append(tfile.infoString);

    // If this is a directory then write to the directorysizes file
    if (!tfile.file_path.isSymlink && tfile.file_path.isDir) {
        const ulong size = tfile.getSize();
        OPTS.dirsize_file.append(format("%s %s %s\n", size, now.toUnixTime(), tfile.file_name));
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
    // MUST call .array() to ensure this doesn't get altered by subsequent algos
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
  List out the files that are in the trash bin but do not have matching
  .trashinfo files so would not show up in --list.
  These can be secretly lurking files that are wasting space
*/
void orphans() {
    const auto files = OPTS.files_dir.dirEntries(SpanMode.shallow).array();

    // If the trash is empty then say so
    if (files.length <= 0) {
        writeln("No orphaned files");
        return;
    }

    auto tf = files.map!(f => buildNormalizedPath(OPTS.info_dir, f) ~ ".trashinfo")
        .filter!(p => !p.exists());

    foreach (TrashFile file; tf) {
        writefln("%s", buildNormalizedPath(OPTS.files_dir, file.file_name));
    }
    writefln("\nUse %s --empty to delete these permanently", OPTS.prog_name);
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
        // If the original desination is writeable
        if (tfile.writeable
                || prompt("%s is write protected, attempt restore anyway?", tfile.orig_path)) {
            tfile.file_path.renameOrCopy(tfile.orig_path);
        }
    }
    // Always remove the trashinfo file
    tfile.info_path.remove();

    // Write a new directorysizes file with the appropriate line removed
    dstring new_dirsize = File(OPTS.dirsize_file).byLine()
        .filter!(l => !l.endsWith(tfile.file_name)).join('\n').array().to!dstring;
    File(OPTS.dirsize_file, "w").write(new_dirsize);

    return 0;
}
