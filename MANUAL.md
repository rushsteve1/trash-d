---
title: TRASH-D
section: 1
header: User Manual
footer: trash-d 14
date: November 24, 2021
---

NAME
====

trash-d - A near drop-in replacement for **rm** that uses the trash bin

SYNOPSIS
========

trash [_option_]... _file_...

DESCRIPTION
===========

A near drop-in replacement for **rm**(1) that uses the FreeDesktop trash bin.
Written in the D programming language using only D's Phobos standard library.

One of **trash-d**'s primary goals is near compatibility with the standard
**rm** tool.The keyword here is "near". The goal is not exact flag-for-flag
compatibility with **rm**, but you should be able to **alias rm=trash** and not
notice the difference.

OPTIONS
=======

The options and flags are intended to mirror **rm**'s closely, with some
additional long options for the **trash-d** specific features.

Because of this, **trash-d** will silently ignore unknown options.  Be warned
that this may be subject to change as **trash-d**'s compatibility with **rm**
increases.

**-d**, **-\-dir**
: Remove empty directories.

**-r**, **-\-recursive**
: Delete directories and their contents.

**-v**, **-\-verbose**
: Print more information.

**-i**, **-\-interactive**
: Ask before each deletion.

**-f**, **-\-force**
: Don't prompt and ignore errors.

**-\-version**
: Output the version and exit.

**-\-list**
: List out the files in the trash.

**-\-orphans**
: List orphaned files in the trash.

**-\-delete** _file_
: Delete a file from the trash.

**-\-restore** _file_
: Restore a file from the trash.

**-\-empty**
: Empty the trash bin.

**-\-rm** _files_...
: Escape hatch to permanently delete a file.

**-h**, **-\-help**
: This help information.


Precedence
----------

The **-\-help**, **-\-version**, **-\-list**, **-\-orphans**, **-\-restore**,
**-\-delete**, and **-\-empty** flags all cause the program to short-circuit and
perform only that operation and no others. Their precedence is in that order
exactly, and is intended to cause the least destruction.

Therefore the command **trash -\-empty -\-list** will list the trash bin and NOT empty
it.

Before version 11 **trash-d** followed a slightly incorrect precedence order.

ENVIRONMENT
===========

**XDG_DATA_HOME**
: This variable is used to determine where the default trash directory is for
  this user as per the FreeDesktop specification.

**TRASH_D_DIR**
: Override the trash directory to the specified path.

EXIT STATUS
===========

**trash-d** exits 0 on success, and >0 if an error occurs.

SEE ALSO
========

**rm**(1), **user-dirs.conf**(5)

STANDARDS
=========

By mimicing **rm** this utility is partially POSIX compliant however this is
**NOT** to be relied upon for any purpose.

The **trash-d** utility is compliant with the FreeDesktop trash specification.
https://specifications.freedesktop.org/trash-spec/trashspec-latest.html

AUTHOR
======

Steven vanZyl <rushsteve1@rushsteve1.us>

The up-to-date sources can be found at https://github.com/rushsteve1/trash-d

BUGS
====

https://github.com/rushsteve1/trash-d/issues
