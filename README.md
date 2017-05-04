FBP Network Protocol
====================

[![Greenkeeper badge](https://badges.greenkeeper.io/flowbased/fbp-protocol.svg)](https://greenkeeper.io/)

Tests, schemas, and specifications for the Flow Based Programming Network Protocol.

You can find a built version of the specification at [flowbased.github.io/fbp-protocol](http://flowbased.github.io/fbp-protocol/).

The included test suite provide an easy way for developers to test their runtimes for compatibility with the protocol.
Also included are files useful to runtime developers, such as message schemas.

The test suite currently works for runtimes based on the Websocket transport.

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

1. Before you can run the tests (successfully), your runtime needs to provide a few basic components. These are currently `Repeat`, `Drop`, and `Output`.

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

If the runtime execution requires a `secret` to be sent, define it using the `FBP_PROTOCOL_SECRET` environment variable.

Examples
--------

A Node.js package using grunt: https://github.com/chadrik/noflo-runtime-websocket/tree/fbp-protocol


Contributing
------------

JSON schemas are built from YAML schemas in schema/yaml. Improvements and
additions to the schemas should be added there. The JSON schemas use
[json-schema](http://json-schema.org/) to validate protocol messages. To run tests,
use grunt test, which will run unit tests for the schemas and fbp-test.
To build the schemas after updating the YAML files, run grunt build, which will
create the JSON schemas, put them together for easy usage in schema/schemas.js,
and update the docs with the latest schema definitions.


TODO
----
- handle `fbp-test -h`
- capture server output to a log
- isolate tests, so that one failure does not cause subsequent tests to fail
- don't test capabilities that the runtime does not claim to support (as returned by `getruntime`)
- add more tests:
  - `getsource` / `source`
  - topology restrictions
  - capturing output
  - existing tests from other projects:
    - https://github.com/jonnor/imgflo/blob/master/spec/websocket.coffee
    - https://github.com/jonnor/sndflo/blob/master/spec/runtime.coffee
    - https://github.com/jonnor/javafbp-runtime/blob/master/spec/protocol.coffee
    - https://github.com/microflo/microflo/blob/master/test/websocketapi.js
- add examples (https://github.com/flowbased/protocol-examples)
- add tests for `fpb-test`
- add separate, optional tests for "classical" or "noflo" behaviors
- use library for more flexible json comparison?
  - [joi](https://github.com/hapijs/joi)
  - [chai-json-schema](http://chaijs.com/plugins/chai-json-schema)
- dynamically build tests based on sidecar json command / response files?
- validate options read from `fbp-config.json`
- make `fbp-init` prompt-based?
- allow `fbp-test /path/to/fbp-config.json`
- make `init` and `test` subcommands of a `fbp` command?
