/**
  The main entrypoint of trash-d
  This is split from the bulk of the implementation which lives in `trash.d`.
  The two files are separated for testing purposes
*/

import run : runCommands;
import cli : OPTS, parseOpts;
import util : err;

import core.memory;
import std.file : FileException;

/**
   The venerable entrypoint function. Does some setup, calls `parseOpts()`, then
   calls `runCommands()` and handles any errors.
*/
int main(string[] args) {
    // Due to the short-lived CLI nature of this program,
    // I have opted to disable the garbage collector.
    // This should squeeze out a bit of performance,
    // while ultimately not affecting memory usage very much
    GC.disable();

    // Parse the command line options
    const int res = parseOpts(args);
    switch (res) {
        case 0:
            break;
            // This is a special case where the options parsing wants to stop
            // execution but there was no error
        case -1:
            return 0;
        default:
            return res;
    }

    // Everything is wrapped in a single outermost try/catch block
    // to make error handling much simpler.
    try {
        return runCommands(args);
    } catch (FileException e) {
        err(e.message());
        return 1;
    }
}
