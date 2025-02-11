/*
Helper utility functions to perform various common operations
*/

module trash.util;

import trash.opts : OPTS;

import core.stdc.errno : EXDEV;
import std.stdio : stderr, stdin, writef;
import std.file;
import std.format : format;
import std.string : strip, toLower, endsWith, chop;
import std.path : buildNormalizedPath, relativePath, absolutePath;

/**
Prints a formatted error message to stderr with the program name at the
beginning
*/
@trusted void err(Char, A...)(in Char[] fmt, A args) {
	stderr.writefln("%s: " ~ fmt, OPTS.prog_name, args);
}

/**
Same as `err()` but only prints if `OPTS.verbose` is true
*/
@safe void log(Char, A...)(in Char[] fmt, A args) {
	if (OPTS.verbose) {
		err("log: " ~ fmt, args);
	}
}

/**
Same as `err()` but only prints if `OPTS.force` is false
*/
@safe int ferr(Char, A...)(in Char[] fmt, A args) {
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
@trusted bool prompt(Char, A...)(in Char[] fmt, A args) {
	writef(OPTS.prog_name ~ " : Are you sure you want to %s? [y/N] ", format(fmt, args));
	string input = stdin.readln().strip().toLower();
	return input == "y" || input == "yes";
}

/**
Same as `prompt()` but only prompts if `OPTS.interactive` is true and
`OPTS.force` is false
*/
@safe bool iprompt(Char, A...)(in Char[] fmt, A args) {
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
@safe void createMissingFolders() {
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
across. In that case perform a copy then remove, descending recursively if
needed.
Symlinks are NOT followed recursively
*/
@trusted bool renameOrCopy(in string src, in string tgt) {
	try {
		// Bit of an odd workaround to prevent recursive trashing
		if (src.endsWith("/") && src.chop().isSymlink) {
			log("'%s' is a symlink, it will not be followed", src);
			src.chop.rename(tgt);
		} else {
			src.rename(tgt);
		}
	} catch (FileException e) {
		if (e.errno != EXDEV)
			throw e;

		if (src.isFile || src.isSymlink) {
			src.copy(tgt);
			src.remove();
		} else if (src.isDir) {
			tgt.mkdir();
			foreach (string name; src.dirEntries(SpanMode.shallow)) {
				string rel = name.absolutePath().relativePath(src.absolutePath());
				string path = buildNormalizedPath(tgt, rel);
				name.renameOrCopy(path);
			}
			src.rmdir();
		} else {
			err("'%s' is not a regular file and cannot be trashed across devices", src);
			return false;
		}
	}
	return true;
}

/**
Is it OK to delete this folder (if it is one). This looks at `OPTS.recusive`
and `OPTS.dir` and the status and contents of `path` to determine if the user
wants the action to be allowable.
*/
@trusted bool dirOk(in string path) {
	if (path.isSymlink) {
		log("'%s' is a symbolic link to a directory", path);
		return true;
	} else if (!OPTS.recursive && path.isDir()) {
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
