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

@safe private int version_from_json() {
	return DUB_JSON.parseJSON()["version"].str.split(".")[0].to!int;
}

// This was originally extracted from the JSON as well
// but a Dub update didn't like that
/// Ever major release is given a new name
/// Names are based on video game bosses
const string VER_NAME = version_name_from_json();

@safe private string version_name_from_json() {
	return DUB_JSON.parseJSON()["versionName"].get!string;
}

/// The full version string
const string VER_TEXT = format("trash-d version %s '%s'\nBuilt at %s with %s", VER, VER_NAME, __TIMESTAMP__, __VENDOR__);

/// The short copyright text and info
const string COPY_TEXT = copy_text_from_json();

@trusted private string copy_text_from_json() {
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
