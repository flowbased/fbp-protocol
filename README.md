FBP Network Protocol
====================

Tests, schemas, and specifications for the Flow Based Programming Network Protocol.

The primary purpose of this project is to provide an easy way for developers to test their runtimes for compatibility with the [FBP Network Protocol](http://noflojs.org/documentation/protocol/). It also contains files useful to runtime developers, such as message schemas. 

The test suite currently works for runtimes based on the websocket transport.

Installing the test suite
-------------------------

1. Install Node.js using their [installer](http://nodejs.org/download/) or a [package manager](https://github.com/joyent/node/wiki/installing-node.js-via-package-manager)

2. Install this package.

   You can install it within your project, which will place the executables in `./node_modules/.bin`:

   ```
   cd /path/to/my/project
   npm install fbp-protocol
   ```

   Or globally, which should put executables on the `PATH`:

   ```
   sudo npm install fbp-protocol -g
   ```


Testing a runtime
-----------------

1. Before you can run the tests (successfully), your runtime needs to provide a few basic components.  These are currently Repeat, Drop, and Output.

   By default, the tests will look for these in the "core" collection, however this is configurable.  For example, if you want to implement these components as a one-off just for the tests, you can place them in a "tests" collection and pass `--collection tests` to `fbp-init`.

2. Use `fbp-init` to save a configuration file for your runtime into the current directory (keep in mind that if you used the local install method, you'll need to run `./node_modules/.bin/fbp-init`).  Use `fbp-init -h` to see the available options and their defaults. 

   Here's an example:

   ```
   fbp-init --name protoflo --port 3569 --command "python -m protoflo runtime"
   ```

   This will produce the file `fbp-protocol.json` in the current directory. Its location within your project is not important, but it needs to be in the current working directory when you run the tests.

3. Run the tests:

   ```
   fbp-test
   ```

Examples
--------

A Node.js package using grunt: https://github.com/chadrik/noflo-runtime-websocket/tree/fbp-protocol


TODO
----
- capture server output to a log
- isolate tests, so that one failure does not cause subsequent tests to fail
- don't test capabilities that the runtime does not claim to support (as returned by `getruntime`)
- add more tests:
  - `getsource` / `source`
  - topology restrictions
  - capturing output
- add separate, optional tests for "classical" or "noflo" behaviors
- use library for more flexible json comparison?
  - [joi](https://github.com/hapijs/joi)
  - [chai-json-schema](http://chaijs.com/plugins/chai-json-schema)
- dynamically build tests based on separate json command / response files?
- validate options read from `fbp-config.json`
- make `fbp-init` prompt-based?
- allow passing a path to `fbp-config.json` to `fbp-test`
- make `init` and `test` subcommands of a `fbp` command?
