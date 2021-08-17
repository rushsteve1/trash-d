/*
  Integration tests for trash-d
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

import trash;

import std.file;
import std.path;
import std.range;
import std.algorithm;

const test_trash_dir = "test-trash";

/**
   A "mini" version of the `main()` function that does no error handling and
   overrides the trash directory for testing purposes.
*/
int mini(string[] args) {
    args = ["trash"] ~ args;
    const int res = parseOpts(args);
    if (res != 0)
        return res;

    // Enable verbosity and change the trash directory for testing
    OPTS.verbose = true;
    OPTS.trash_dir = test_trash_dir;

    return runCommands(args);
}

/**
   Test the options parser to ensure that the right options are set when the
   flags are given
*/
unittest {
    // requires arg[0] to be the program name
    auto t = ["trash"];

    string[] args = t ~ ["-f"];
    parseOpts(args);
    assert(OPTS.force);

    args = t ~ ["-d"];
    parseOpts(args);
    assert(OPTS.dir);

    args = t ~ ["-r"];
    parseOpts(args);
    assert(OPTS.recursive);

    args = t ~ ["-rf"];
    parseOpts(args);
    assert(OPTS.recursive);
    assert(OPTS.force);

    args = t ~ ["--list"];
    parseOpts(args);
    assert(OPTS.list);

    args = t ~ ["-f", "--empty"];
    parseOpts(args);
    assert(OPTS.force);
    assert(OPTS.empty);

    assert(mini(["--version"]) == -1);
    assert(mini(["--help"]) == -1);
}

/**
   Test the basic usecase of trashing then restoring a single file
*/
unittest {
    string testfile = "test.file";
    testfile.write("hello");
    scope (exit)
        testfile.remove();
    assert(testfile.exists());
    auto tinfo = TrashFile(testfile);

    // Trash the file
    assert(mini([testfile]) == 0);
    assert(!testfile.exists());
    assert(tinfo.file_path.exists());
    assert(tinfo.info_path.exists());

    // List the trash and ensure nothing changed
    assert(mini(["--list"]) == 0);
    assert(!testfile.exists());
    assert(tinfo.file_path.exists());
    assert(tinfo.info_path.exists());

    // Restore the file
    assert(mini(["--restore", testfile]) == 0);
    assert(testfile.exists());
    assert(!tinfo.file_path.exists());
    assert(!tinfo.info_path.exists());

    // Cleanup
    scope (success)
        test_trash_dir.rmdirRecurse();
}

/**
   Test the usecase of trashing an empty folder, including the failing case
   without the -d flag, and then permanently deleting the folder from the trash
*/
unittest {
    string testdir = "test-dir";
    testdir.mkdir();
    scope (failure)
        testdir.rmdir();
    assert(testdir.exists());
    auto tinfo = TrashFile(testdir);

    // Should not trash a directory without -d
    assert(mini([testdir]) == 1);
    assert(testdir.exists());
    assert(!tinfo.file_path.exists());
    assert(!tinfo.info_path.exists());

    // Now it should with the -d flag
    assert(mini([testdir, "-d"]) == 0);
    assert(!testdir.exists());
    assert(tinfo.file_path.exists());
    assert(tinfo.info_path.exists());

    // Delete it from the trash
    assert(mini(["--delete", testdir]) == 0);
    assert(!tinfo.file_path.exists());
    assert(!tinfo.info_path.exists());

    // Cleanup
    scope (success)
        test_trash_dir.rmdirRecurse();
}

/**
   Test the --rm flag
*/
unittest {
    string testfile = "test.file";
    testfile.write("hello");
    assert(testfile.exists());
    auto tinfo = TrashFile(testfile);

    // The file should be removed but NOT moved to the trash
    assert(mini(["--rm", testfile]) == 0);
    assert(!testfile.exists());
    assert(!tinfo.file_path.exists());
    assert(!tinfo.info_path.exists());

    // Cleanup
    scope (success)
        test_trash_dir.rmdirRecurse();
}

/**
   Test recursively trashing a folder then emptying the trash
*/
unittest {
    string testdir = "test-dir";
    testdir.mkdir();
    scope (failure)
        testdir.rmdirRecurse();
    assert(testdir.exists());
    auto tinfo = TrashFile(testdir);

    string testfile = testdir ~ "/test.file";
    testfile.write("hello");
    assert(testfile.exists());

    // Should not work
    assert(mini([testdir]) != 0);
    assert(testdir.exists());
    assert(!tinfo.file_path.exists());
    assert(!tinfo.info_path.exists());

    // Also should not work
    assert(mini(["-d", testdir]) != 0);
    assert(testdir.exists());
    assert(!tinfo.file_path.exists());
    assert(!tinfo.info_path.exists());

    // Should work
    assert(mini(["-r", testdir]) == 0);
    assert(!testdir.exists());
    assert(tinfo.file_path.exists());
    assert(tinfo.info_path.exists());
    assert(!std.range.empty(OPTS.dirsize_file.readText().find(testdir)));

    // Empty the trash
    assert(mini(["-f", "--empty"]) == 0);
    assert(!tinfo.file_path.exists());
    assert(!tinfo.info_path.exists());
    assert(!OPTS.files_dir.exists());
    assert(!OPTS.info_dir.exists());
    assert(!OPTS.dirsize_file.exists());

    // Cleanup
    scope (success)
        test_trash_dir.rmdirRecurse();
}

/**
   Handle trashing two files with the same name
*/
unittest {
    // Write one file and trash it
    string testfile = "test.file";
    testfile.write("hello");
    auto tinfo = TrashFile(testfile);

    // Yes this repeats the other test
    // Doesn't hurt to test the main purpose of the program twice
    assert(mini([testfile]) == 0);
    assert(!testfile.exists());
    assert(tinfo.file_path.exists());
    assert(tinfo.info_path.exists());

    // Write another then trash that too
    testfile.write("hello");
    assert(testfile.exists());

    assert(mini([testfile]) == 0);

    // There should be two files matching in both directories
    ulong ct = OPTS.files_dir.dirEntries(SpanMode.shallow)
        .filter!(f => f.name.pathSplitter().array()[$ - 1].startsWith(testfile)).array().length;
    assert(ct == 2);

    ct = OPTS.info_dir.dirEntries(SpanMode.shallow)
        .filter!(f => f.name.pathSplitter().array()[$ - 1].startsWith(testfile)).array().length;
    assert(ct == 2);

    // Cleanup
    scope (success)
        test_trash_dir.rmdirRecurse();
}

/**
   Intentionally failing cases to ensure that these are properly handled and for
   code coverage
*/
unittest {
    const string ne = "nonexist";
    assert(!ne.exists());

    // Too few arguments
    assert(mini([]) == 1);

    // Trashing a file that doesn't exist
    assert(mini([ne]) == 1);
    // But -f should make it pass
    assert(mini(["-f", ne]) == 0);

    // Restoring a file that doesn't exist
    assert(mini(["--resotre", ne]) == 1);
    // Deleting a file that doesn't exist

    // Cleanup
    scope (success)
        test_trash_dir.rmdirRecurse();
}

/**
   Trash from /tmp/
   On most systems (including mine) this is a separate tempfs so this test is
   for cross-filesystem trashing
*/
unittest {
    string testfile = "/tmp/test.file";
    testfile.write("hello");
    scope (exit)
        testfile.remove();
    assert(testfile.exists());
    auto tinfo = TrashFile("test.file");

    // Trash the file
    assert(mini([testfile]) == 0);

    assert(!testfile.exists());
    assert(tinfo.file_path.exists());
    assert(tinfo.info_path.exists());

    // Restore the file
    assert(mini(["--restore", "test.file"]) == 0);
    assert(testfile.exists());
    assert(!tinfo.file_path.exists());
    assert(!tinfo.info_path.exists());

    // Cleanup
    scope (success)
        test_trash_dir.rmdirRecurse();
}
