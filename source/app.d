/*
  The main entrypoint of trash-d
  This is split from the bulk of the implementation which lives in `trash.d`.
  The two files are separated for testing purposes
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
