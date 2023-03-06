/**
Version and copyright information that gets bundled in with trash-d
*/

module trash.ver;

import std.array;
import std.conv: to;
import std.format: format;
import std.json;

/// The dub.json file inlined as a string
const string DUB_JSON = import("dub.json");

/// trash-d is versioned sequentially starting at 1
const int VER = version_from_json();

/// Ever major release is given a new name
/// Names are based on video game bosses
const string VER_NAME = version_name_from_json();

/// The full version string
const string VER_TEXT = format("trash-d version %s '%s'", VER, VER_NAME);

/// The short copyright text and info
const string COPY_TEXT = copy_text_from_json();

private int version_from_json() {
	return DUB_JSON.parseJSON()["version"].str.split(".")[0].to!int;
}

private string version_name_from_json() {
	return DUB_JSON.parseJSON()["versionName"].str;
}

private string copy_text_from_json() {
	import std.range;
	import std.array;
	import std.algorithm;

	auto j = DUB_JSON.parseJSON();
	string authors = j["authors"].array.map!(`a.str`).join(", ");

	return format("%s
License %s <https://spdx.org/licenses/%s.html>.
Fork on GitHub <%s>

This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Written by %s.", j["copyright"].str, j["license"].str, j["license"].str,
	j["homepage"].str, authors);
}
