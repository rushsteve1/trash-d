/**
TrashFile structure which handles information related to a file in the trash
*/

module trash.file;

import trash.opts : OPTS;
import trash.util : log, err;

import core.sys.posix.sys.stat : S_IWUSR;
import std.algorithm : filter, map, sum;
import std.datetime.systime : SysTime;
import std.file;
import std.path;
import std.random : uniform;
import std.format : formattedRead;
import std.string;

/**
This struct wraps data about a single file in the trash (or that is being
moved to the trash).
It provides facilities for getting related info about a file and for
generating and parsing its `.trashinfo` file
*/
struct TrashFile {
	/// Format string used to parse and format the `.trashinfo` files
	const string info_fstr = "[Trash Info]\nPath=%s\nDeletionDate=%s\n";
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
	@safe this(in string n) {
		file_name = n.baseName();

		if (exists(info_path)) {
			parseInfo();
		} else {
			err("no info file: '%s'", info_path);
		}
	}

	/**
	When given a string and a `SysTime` the constructor assumes that this is
	a file that is about to be added to the trash bin.
	*/
	@safe this(in string p, in SysTime now) {
		orig_path = p.buildNormalizedPath().absolutePath();
		file_name = orig_path.baseName().chompPrefix(".");

		if (!orig_path.isSymlink && orig_path.isDir() && orig_path.endsWith("/")) {
			orig_path = orig_path.chop();
		}

		// If a file with the same name exists in the trash,
		// generate a random 4-digit numeric suffix
		if (file_path.exists()) {
			file_name = format("%s-%s", file_name, uniform(1000, 9999));
		}

		deletion_date = now;
	}

	/// Path to the file in the trash bin
	@property @safe string file_path() const nothrow {
		return OPTS.files_dir.buildPath(file_name);
	}

	/// Path to the matching `.trashinfo` file
	@property @safe string info_path() const {
		return OPTS.info_dir.buildPath(file_name) ~ ".trashinfo";
	}

	/// Is the file at this location writeable according to `attr_orig`
	@property @safe bool writeable() const {
		uint attr_orig = 0;
		if (orig_path.exists() && !orig_path.isSymlink) {
			attr_orig = orig_path.getAttributes();
		} else if (orig_path.dirName.exists()) {
			attr_orig = orig_path.dirName.getAttributes();
		}

		return cast(bool)(attr_orig & S_IWUSR);
	}

	/// Parses the related `.trashinfo` file, pulling the info from it
	@trusted void parseInfo() {
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

	/// Gets the size of the file or folder, walking through directories if needed
	@trusted ulong getSize() const {
		if (file_path.isDir()) {
			return file_path.dirEntries(SpanMode.depth, false).filter!(e => e.isFile())
				.map!(e => e.getSize())
				.sum();
		}
		return file_path.getSize();
	}
}
