/**
   Version and copyright information that gets bundled in with trash-d
*/

import std.format : format;

/// trash-d is versioned sequentially starting at 1
const int VER = 14;

/// Ever major release is given a new name
/// Names are based on video game bosses
const string VER_NAME = "Clifford Unger";

/// The full version string
const string VER_TEXT = format("trash-d version %s '%s'", VER, VER_NAME);

/// The short copyright text and info
const string COPY_TEXT = "Copyright (C) 2021 Steven vanZyl.
License MIT <https://mit-license.org/>.
Fork on GitHub <https://github.com/rushsteve1/trash-d>

This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Written by Steven vanZyl <rushsteve1@rushsteve1.us>.";
