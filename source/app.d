/**
  The main entrypoint of trash-d
  This is split from the bulk of the implementation and are separated for
  testing purposes
*/

import trash.run : runCommands;
import trash.opts : OPTS, parseOpts;
import trash.util : err;

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
        case -1:
            // This is a special case where the options parsing wants to stop
            // execution but there was no error
            return 0;
        default:
            return res;
    }

    debug {
        // ONLY IN DEBUG MODE

        return runCommands(args);
    } else {
        // ONLY IN RELEASE MODE

        // Everything is wrapped in a single outermost try/catch block
        // to make error handling much simpler.
        try {
            return runCommands(args);
        } catch (FileException e) {
            err(e.message());
            return 1;
        }
    }
}
