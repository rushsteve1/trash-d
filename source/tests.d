/**
  Integration tests for trash-d
*/

import trash.run : runCommands;
import trash.opts : OPTS, parseOpts;
import trash.file : TrashFile;

import std.file;
import std.path;
import std.range;
import std.string;
import std.algorithm;
import std.conv : octal;
import std.datetime.systime : Clock;
import core.sys.posix.sys.stat;

const test_trash_dir = "test-trash";

/**
   A "mini" version of the `main()` function that does no error handling and
   overrides the trash directory for testing purposes.
*/
int mini(string[] args) {
    args = ["trash"] ~ args;
    const int res = parseOpts(args);
    if (res == -1) {
        // special return value meaning no failures but exit now
        return 0;
    } else if (res != 0) {
        return res;
    }

    // Test for a nasty bug that came up
    assert(!(OPTS.trash_dir is null));

    // Enable verbosity and change the trash directory for testing
    OPTS.verbose = true;
    OPTS.trash_dir = test_trash_dir;

    return runCommands(args);
}

/**
   Create a file with a given name, then trash it using args
*/
void assert_args_delete(string testfile, string[] args) {
    // Write one file and trash it
    testfile.write("hello");
    auto tinfo = TrashFile(testfile, Clock.currTime());

    // Yes this repeats the other test
    // Doesn't hurt to test the main purpose of the program thrice
    assert(mini(args) == 0);
    assert(!testfile.exists());
    assert(tinfo.file_path.exists());
    assert(tinfo.info_path.exists());

    // Cleanup
    scope (success)
        test_trash_dir.rmdirRecurse();
}

/**
   Create multiple files, then trash them using args
*/
void assert_args_delete_multiple(string[] testfiles, string[] args) {
    TrashFile[] tinfos = [];

    // Write one file and trash it
    foreach (string testfile; testfiles) {
        testfile.write("hello");
        tinfos = tinfos ~ TrashFile(testfile, Clock.currTime());
    }

    // Yes this repeats the other test
    // and it is going a bit overboard now
    assert(mini(args) == 0);

    foreach (string testfile; testfiles) {
        assert(!testfile.exists());
    }

    foreach (TrashFile tinfo; tinfos) {
        assert(tinfo.file_path.exists());
        assert(tinfo.info_path.exists());
    }

    // Cleanup
    scope (success)
        test_trash_dir.rmdirRecurse();
}

/**
   Test the options parser to ensure that the right options are set when the
   flags are given
*/
unittest {
    // requires arg[0] to be the program name
    const string[] t = ["trash"];

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

    args = t ~ ["--orphans"];
    parseOpts(args);
    assert(OPTS.orphans);

    args = t ~ ["-f", "--empty"];
    parseOpts(args);
    assert(OPTS.force);
    assert(OPTS.empty);

    assert(mini(["--version"]) == 0);
    assert(mini(["--help"]) == 0);
}

/**
   Test the basic usecase of trashing then restoring a single file
*/
unittest {
    string testfile = "test.file";
    testfile.write("hello");
    // Remove in either case since it will be restored
    scope (exit)
        testfile.remove();
    assert(testfile.exists());
    auto tinfo = TrashFile(testfile, Clock.currTime());
    assert(tinfo.writeable);

    // Trash the file
    assert(mini([testfile]) == 0);
    assert(!testfile.exists());
    assert(tinfo.file_path.exists());
    assert(tinfo.info_path.exists());

    // List the trash and everything is in the right place
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
   Test that deletions continue after a failure
*/
unittest {
    string testfile = "test.file";
    testfile.write("hello");
    assert(testfile.exists());
    auto tinfo = TrashFile(testfile, Clock.currTime());
    assert(tinfo.writeable);

    // This should return non-zero,
    // indicating that there was at least one error,
    // but testfile should be trashed.
    assert(mini(["does-not-exist", testfile]) != 0);
    assert(!testfile.exists());
    assert(tinfo.file_path.exists());
    assert(tinfo.info_path.exists());

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
    auto tinfo = TrashFile(testdir, Clock.currTime());

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
    auto tinfo = TrashFile(testfile, Clock.currTime());

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
    string testdir = "test-dir/";
    testdir.mkdir();
    scope (failure)
        testdir.rmdirRecurse();
    assert(testdir.exists());
    auto tinfo = TrashFile(testdir, Clock.currTime());

    string testfile = testdir ~ "/test.file";
    testfile.write("hello");
    assert(testfile.exists());

    // Should not work
    assert(mini([testdir]) != 0);
    assert(testdir.exists());
    assert(!tinfo.file_path.exists());
    assert(!tinfo.info_path.exists());
    assert(!OPTS.dirsize_file.readText().canFind(tinfo.file_name));

    // Also should not work
    assert(mini(["-d", testdir]) != 0);
    assert(testdir.exists());
    assert(!tinfo.file_path.exists());
    assert(!tinfo.info_path.exists());
    assert(!OPTS.dirsize_file.readText().canFind(tinfo.file_name));

    // Should work
    assert(mini(["-r", testdir]) == 0);
    assert(!testdir.exists());
    assert(tinfo.file_path.exists());
    assert(tinfo.info_path.exists());
    assert(OPTS.dirsize_file.readText().canFind(tinfo.file_name));

    // Empty the trash
    assert(mini(["-f", "--empty"]) == 0);
    assert(!tinfo.file_path.exists());
    assert(!tinfo.info_path.exists());
    assert(OPTS.files_dir.exists());
    assert(OPTS.info_dir.exists());
    assert(OPTS.dirsize_file.exists());

    // Empty operands should error
    assert(mini(["-f"]) == 1);

    // Cleanup
    scope (success)
        test_trash_dir.rmdirRecurse();
}

/**
   Test recursively deleting a folder with --rm
*/
unittest {
    string testdir = "test-dir";
    testdir.mkdir();
    scope (failure)
        testdir.rmdirRecurse();
    assert(testdir.exists());
    auto tinfo = TrashFile(testdir, Clock.currTime());

    string testfile = testdir ~ "/test.file";
    testfile.write("hello");
    assert(testfile.exists());

    // Should work
    assert(mini(["--rm", "-r", testdir]) == 0);
    assert(!testdir.exists());
    assert(!tinfo.file_path.exists());
    assert(!tinfo.info_path.exists());
    assert(!OPTS.dirsize_file.readText().canFind(tinfo.file_name));

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
    auto tinfo = TrashFile(testfile, Clock.currTime());

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
   Handle trashing filenames beginning with '-' 
*/
unittest {
    assert_args_delete("testfile", ["testfile"]);
    assert_args_delete("testfile", ["--", "testfile"]);
    assert_args_delete("testfile", ["-f", "--", "testfile"]);
    assert_args_delete("-z", ["--", "-z"]);
    assert_args_delete("--z", ["--", "--z"]);
    assert_args_delete("--xxx", ["--", "--xxx"]);
    assert_args_delete_multiple(["-z", "--xx", "--xxx"], [
            "--", "-z", "--xx", "--xxx"
            ]);
    assert_args_delete_multiple(["testfile", "--xxx"], [
            "testfile", "-f", "--", "--xxx"
            ]);
}

/**
   Trash from /tmp/
   On most systems (including mine) this is a separate tempfs so this test is
   for cross-filesystem trashing
   But in the CI pipeline it is not a separate filesystem, so this has to be
   tested locally for real results.
*/
unittest {
    string testfile = "/tmp/test.file";
    testfile.write("hello");
    // Remove in either case since it will be restored
    scope (exit)
        testfile.remove();
    assert(testfile.exists());
    auto tinfo = TrashFile(testfile, Clock.currTime());

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

/**
   Trash a directory containing a file from /tmp/
   On most systems (including mine) this is a separate tempfs so this test is
   for cross-filesystem trashing
*/
unittest {
    string testdir = "/tmp/tdir";
    testdir.mkdir();
    string testfile = testdir ~ "/test.file";
    testfile.write("hello");
    scope (exit)
        testdir.rmdirRecurse();
    assert(testdir.exists());
    assert(testfile.exists());
    auto tinfo = TrashFile(testdir, Clock.currTime());

    // Trash the file
    assert(mini(["-r", testdir]) == 0);

    assert(!testdir.exists());
    assert(!testfile.exists());
    assert(tinfo.file_path.exists());
    assert(tinfo.info_path.exists());

    // Restore the file
    assert(mini(["--restore", "tdir"]) == 0);
    assert(testdir.exists());
    assert(testfile.exists());
    assert(!tinfo.file_path.exists());
    assert(!tinfo.info_path.exists());

    // Cleanup
    scope (success)
        test_trash_dir.rmdirRecurse();
}

/**
   Test trashing a file that does not have write permissions
*/
unittest {
    string testfile = "test.file";
    testfile.write("hello");
    chmod(testfile.toStringz(), octal!444);
    scope (failure)
        testfile.remove();
    assert(testfile.exists());
    auto tinfo = TrashFile(testfile, Clock.currTime());
    assert(!tinfo.writeable);

    // Trash the file with -f
    assert(mini(["-f", testfile]) == 0);
    assert(!testfile.exists());
    assert(tinfo.file_path.exists());
    assert(tinfo.info_path.exists());

    // Cleanup
    scope (success)
        test_trash_dir.rmdirRecurse();
}

/**
   Test the orpahans command which lists files without trashinfos
*/
unittest {
    // Run a command so that the trash directory is created
    assert(mini(["--list"]) == 0);

    const string testname = "test.file";
    string testfile = OPTS.files_dir ~ "/" ~ testname;
    testfile.write("hello");
    scope (failure)
        testfile.remove();
    assert(testfile.exists());

    assert(mini(["--orphans"]) == 0);
    assert(testfile.exists());

    // Cleanup
    scope (success)
        test_trash_dir.rmdirRecurse();
}

/**
   Test that broken symlinks are removed properly
*/
unittest {
    const string testfile = "test.file";
    const string testlink = "test.link";
    scope (failure) {
        testlink.remove();
        testfile.remove();
    }

    testfile.write("hello");
    assert(testfile.exists());
    assert(testfile.isFile);

    symlink(testfile, testlink);
    assert(testlink.exists());
    assert(testlink.isSymlink);

    assert(mini([testfile]) == 0);
    assert(mini([testlink]) == 0);

    // Cleanup
    scope (success)
        test_trash_dir.rmdirRecurse();
}

/**
    Test removing symlinks to directories properly
*/
unittest {
    const string testdir = "tdir";
    const string testlink = "tdir.link";
    scope (failure) {
        testdir.rmdir();
        testlink.remove();
    }

    testdir.mkdir();
    assert(testdir.exists());
    assert(testdir.isDir);

    symlink(testdir, testlink);
    assert(testlink.exists());
    assert(testlink.isSymlink);

    // These should fail, the slash is very important
    assert(mini([testdir]) != 0);
    assert(mini([testlink ~ "/"]) != 0);

    // This should succeed without the slash
    assert(mini([testlink]) == 0);

    symlink(testdir, testlink);
    assert(testlink.exists());
    assert(testlink.isSymlink);

    // This should succeed with the slash
    assert(mini(["-r", testlink ~ "/"]) == 0);
    assert(mini(["-r", testdir]) == 0);

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
    assert(mini(["--restore", ne]) == 1);
    // Deleting a file that doesn't exist
    assert(mini(["--rm", ne]) == 1);

    // Unknown options should error out
    assert(mini(["--unknown"]) == 1);

    // Cleanup
    scope (success)
        test_trash_dir.rmdirRecurse();
}
