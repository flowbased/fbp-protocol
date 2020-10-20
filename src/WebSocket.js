/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const chai = require('chai');
const path = require('path');
const { spawn } = require('child_process');
const WebSocketClient = require('websocket').client;
const semver = require('semver');
const tv4 = require('../schema/index.js');

const validateSchema = function(payload, schema) {
  const res = tv4.validateMultiple(payload, schema);
  chai.expect(res.errors, `${schema} should produce no errors`).to.eql([]);
  chai.expect(res.valid, `${schema} should validate`).to.equal(true);
  return res.valid;
};

exports.testRuntime = function(runtimeType, startServer, stopServer, host, port, collection, version) {
  let semanticVersion;
  if (host == null) { host = 'localhost'; }
  if (port == null) { port = 8080; }
  if (collection == null) { collection = 'core'; }
  if (version == null) { version = '0.7'; }
  if (version.length === 3) {
    semanticVersion = `${version}.0`;
  } else {
    semanticVersion = version;
  }

  const address = `ws://${host}:${port}/`;
  return describe(`${runtimeType} webSocket network runtime version ${version}`, function() {
    let client = null;
    let connection = null;
    let capabilities = [];
    let send = null;
    describe(`Connecting to the runtime at ${address}`, () => it('should succeed', function(done) {
      this.timeout(4000);
      let tries = 10;
      return startServer(function(err) {
        if (err) { return done(err); }
        client = new WebSocketClient;
        const onConnected = function(conn) {
          connection = conn;
          connection.setMaxListeners(1000);
          client.removeListener('connectFailed', onFailed);
          return done();
        };
        var onFailed = function(err) {
          tries--;
          if (!tries) {
            client.removeListener('connect', onConnected);
            client.removeListener('connectFailed', onFailed);
            done(err);
            return;
          }
          return setTimeout(() => client.connect(address, 'noflo')
          , 100);
        };
        client.once('connect', onConnected);
        client.on('connectFailed', onFailed);
        return client.connect(address, 'noflo');
      });
    }));
    after(function(done) {
      if (!connection) {
        stopServer(done);
        return;
      }
      connection.once('close', function() {
        connection = null;
        return stopServer(done);
      });
      return connection.drop();
    });

    send = function(protocol, command, payload) {
      if (!payload) { payload = {}; }
      // FIXME: Remove from payload once runtimes are on 0.8
      payload.secret = process.env.FBP_PROTOCOL_SECRET;
      return connection.sendUTF(JSON.stringify({
        protocol,
        command,
        payload,
        secret: process.env.FBP_PROTOCOL_SECRET
      })
      );
    };

    const messageMatches = function(msg, expected) {
      if (msg.protocol !== expected.protocol) { return false; }
      if (msg.command !== expected.command) { return false; }
      return true;
    };
    const getPacketSchema = packet => `${packet.protocol}/output/${packet.command}`;

    const receive = function(expects, done, allowExtraPackets) {
      if (allowExtraPackets == null) { allowExtraPackets = false; }
      var listener = function(message) {
        // Basic validation
        chai.expect(message.utf8Data).to.be.a('string');
        const data = JSON.parse(message.utf8Data);
        chai.expect(data.protocol).to.be.a('string');
        chai.expect(data.command).to.be.a('string');

        // FIXME: Remove once runtimes are on 0.8
        delete data.payload.secret;

        // Validate all received packets against schema
        validateSchema(data, getPacketSchema(data));
        // Don't ever expect payloads to return a secret
        chai.expect(data.secret, 'Message should not contain secret').to.be.a('undefined');
        chai.expect(data.payload.secret, 'Payload should not contain secret').to.be.a('undefined');

        if ((expects[0].command !== 'error') && (data.command === 'error')) {
          // We received an unexpected error, bail out
          done(new Error(data.payload));
          return;
        }

        if (allowExtraPackets && !messageMatches(data, expects[0])) {
          // Ignore messages we don't care about in context of the test
          connection.once('message', listener);
          return;
        }

        // Validate actual payload
        const expected = expects.shift();
        chai.expect(getPacketSchema(data)).to.equal(getPacketSchema(expected));

        // Clear values that can't be checked with deep equal. We already
        // know they passed schema validation
        if (data.protocol === 'network') {
          if (data.command === 'started') {
            delete data.payload.time;
            delete expected.payload.time;
            delete data.payload.running;
            delete expected.payload.running;
          }
          if (data.command === 'stopped') {
            delete data.payload.time;
            delete expected.payload.time;
            delete data.payload.uptime;
            delete expected.payload.uptime;
          }
        }
        if (data.command === 'error') {
          delete data.payload.stack;
          delete expected.payload.stack;
        }

        // FIXME: Remove once runtimes are on 0.8
        delete expected.payload.secret;
        // Don't ever expect payloads to return a secret
        delete expected.secret;

        chai.expect(data.payload).to.eql(expected.payload);
        // Received all expected packets
        if (!expects.length) { return done(); }
        // Still waiting
        connection.once('message', listener);
      };
      return connection.once('message', listener);
    };

    describe('Runtime Protocol', function() {
      before(() => chai.expect(connection, 'Connection needs to be available').not.be.a('null'));
      return describe('requesting runtime metadata', () => it('should provide it back', function(done) {
        connection.once('message', function(message) {
          const data = JSON.parse(message.utf8Data);
          validateSchema(data, 'runtime/output/runtime');
          ({
            capabilities
          } = data.payload);
          return done();
        });

        return send('runtime', 'getruntime', {});
    }));
  });

    describe('Graph Protocol', function() {
      before(function() {
        chai.expect(connection, 'Connection needs to be available').not.be.a('null');
        return chai.expect(capabilities, 'Graph protocol should be allowed for user').to.contain('protocol:graph');
      });
      describe('adding a graph and nodes', () => it('should provide the nodes back', function(done) {
        const expects1 = [{
            protocol: 'graph',
            command: 'clear',
            payload: {
              id: 'foo',
              main: true,
              name: 'Foo graph'
            }
          }
        ];
        const expects2 = [{
            protocol: 'graph',
            command: 'addnode',
            payload: {
              id: 'Repeat1',
              component: `${collection}/Repeat`,
              metadata: {
                hello: 'World'
              },
              graph: 'foo'
            }
          }
          , {
            protocol: 'graph',
            command: 'addnode',
            payload: {
              id: 'Drop1',
              component: `${collection}/Drop`,
              metadata: {},
              graph: 'foo'
            }
          }
        ];
        receive(expects1, function(err) {
          if (err) { return done(err); }
          receive(expects2, done, true);
          send('graph', 'addnode', expects2[0].payload);
          return send('graph', 'addnode', expects2[1].payload);
        }
        , true);
        return send('graph', 'clear', {
          baseDir: path.resolve(__dirname, '../'),
          id: 'foo',
          main: true,
          name: 'Foo graph'
        }
        );
      }));

      describe('adding an edge', () => it('should provide the edge back', function(done) {
        const expects = [{
          protocol: 'graph',
          command: 'addedge',
          payload: {
            src: {
              node: 'Repeat1',
              port: 'out'
            },
            tgt: {
              node: 'Drop1',
              port: 'in'
            },
            metadata: {
              route: 5
            },
            graph: 'foo'
          }
        }
        ];
        receive(expects, done, true);
        return send('graph', 'addedge', expects[0].payload);
      }));
      // describe 'adding an edge to a non-existent node', ->
      //   it 'should return an error', (done) ->
      //     expects = [
      //       protocol: 'graph'
      //       command: 'error'
      //       payload:
      //         msg: 'Requested port not found'
      //     ]
      //     receive expects, done
      //     send 'graph', 'addedge',
      //       protocol: 'graph'
      //       command: 'addedge'
      //       payload:
      //         src:
      //           node: 'non-existent'
      //           port: 'out'
      //         tgt:
      //           node: 'Drop1'
      //           port: 'in'
      //         graph: 'foo'
      // describe 'adding an edge to a non-existent port', ->
      //   it 'should return an error', (done) ->
      //     expects = [
      //       protocol: 'graph'
      //       command: 'error'
      //       payload:
      //         msg: 'Requested port not found'
      //     ]
      //     receive expects, done
      //     send 'graph', 'addedge',
      //       protocol: 'graph'
      //       command: 'addedge'
      //       payload:
      //         src:
      //           node: 'Repeat1'
      //           port: 'non-existent'
      //         tgt:
      //           node: 'Drop1'
      //           port: 'in'
      //         graph: 'foo'
      describe('adding metadata', function() {
        describe('to a node with no metadata', () => it('should add the metadata', function(done) {
          const expects = [{
            protocol: 'graph',
            command: 'changenode',
            payload: {
              id: 'Drop1',
              metadata: {
                sort: 1
              },
              graph: 'foo'
            }
          }
          ];
          receive(expects, done, true);
          return send('graph', 'changenode', expects[0].payload);
        }));

        describe('to a node with existing metadata', () => it('should merge the metadata', function(done) {
          const expects = [{
            protocol: 'graph',
            command: 'changenode',
            payload: {
              id: 'Drop1',
              metadata: {
                sort: 1,
                tag: 'awesome'
              },
              graph: 'foo'
            }
          }
          ];
          receive(expects, done, true);
          return send('graph', 'changenode', {
            id: 'Drop1',
            metadata: {
              tag: 'awesome'
            },
            graph: 'foo'
          }
          );
        }));

        describe('with no keys to a node with existing metadata', () => it('should not change the metadata', function(done) {
          const expects = [{
            protocol: 'graph',
            command: 'changenode',
            payload: {
              id: 'Drop1',
              metadata: {
                sort: 1,
                tag: 'awesome'
              },
              graph: 'foo'
            }
          }
          ];
          receive(expects, done, true);
          return send('graph', 'changenode', {
            id: 'Drop1',
            metadata: {},
            graph: 'foo'
          }
          );
        }));

        return describe('with a null value removes it from the node', () => it('should merge the metadata', function(done) {
          const expects = [{
            protocol: 'graph',
            command: 'changenode',
            payload: {
              id: 'Drop1',
              metadata: {},
              graph: 'foo'
            }
          }
          ];
          receive(expects, done, true);
          return send('graph', 'changenode', {
            id: 'Drop1',
            metadata: {
              sort: null,
              tag: null
            },
            graph: 'foo'
          }
          );
        }));
      });

      describe('adding an IIP', () => it('should provide the IIP back', function(done) {
        const expects = [{
          protocol: 'graph',
          command: 'addinitial',
          payload: {
            src: {
              data: 'Hello, world!'
            },
            tgt: {
              node: 'Repeat1',
              port: 'in'
            },
            metadata: {},
            graph: 'foo'
          }
        }
        ];
        receive(expects, done, true);
        return send('graph', 'addinitial', expects[0].payload);
      }));

      describe('removing a node', () => it('should remove the node and its associated edges', function(done) {
        const expects = [{
          protocol: 'graph',
          command: 'removeedge',
          payload: {
            src: {
              node: 'Repeat1',
              port: 'out'
            },
            tgt: {
              node: 'Drop1',
              port: 'in'
            },
            graph: 'foo'
          }
        }
        , {
          protocol: 'graph',
          command: 'removenode',
          payload: {
            id: 'Drop1',
            graph: 'foo'
          }
        }
        ];
        // Runtimes can send 'changeedge' and 'changenode' as part
        // of the response for better fbp-graph/Journal behavior
        receive(expects, done, true);
        return send('graph', 'removenode', {
          id: 'Drop1',
          graph: 'foo'
        }
        );
      }));

      describe('removing an IIP', () => it('should provide response that iip was removed', function(done) {
        const expects = [{
          protocol: 'graph',
          command: 'removeinitial',
          payload: {
            src: {
              data: 'Hello, world!'
            },
            tgt: {
              node: 'Repeat1',
              port: 'in'
            },
            graph: 'foo'
          }
        }
        ];
        receive(expects, done, true);
        return send('graph', 'removeinitial', {
          tgt: {
            node: 'Repeat1',
            port: 'in'
          },
          graph: 'foo'
        }
        );
      }));

      describe('renaming a node', () => it('should send the renamenode event', function(done) {
        const expects = [{
          protocol: 'graph',
          command: 'renamenode',
          payload: {
            from: 'Repeat1',
            to: 'RepeatRenamed',
            graph: 'foo'
          }
        }
        ];
        receive(expects, done, true);
        return send('graph', 'renamenode', expects[0].payload);
      }));

      describe('adding a node to a non-existent graph', () => it('should send an error', function(done) {
        const expects = [{
          protocol: 'graph',
          command: 'error',
          payload: {
            message: 'Requested graph not found'
          }
        }
        ];
        receive(expects, done, true);
        return send('graph', 'addnode', {
          id: 'Repeat1',
          component: `${collection}/Repeat`,
          graph: 'another-graph'
        }
        );
      }));

      describe('adding a node without specifying a graph', () => it('should send an error', function(done) {
        const expects = [{
          protocol: 'graph',
          command: 'error',
          payload: {
            message: 'No graph specified'
          }
        }
        ];
        receive(expects, done, true);
        return send('graph', 'addnode', {
          id: 'Repeat1',
          component: `${collection}/Repeat`
        }
        );
      }));

      describe('adding an in-port to a graph', () => it("should ACK", function(done) {
        const expects = [{
          protocol: 'graph',
          command: 'addinport',
          payload: {
            node: 'RepeatRenamed',
            graph: 'foo',
            public: 'in',
            port: 'in'
          }
        }
        ];
        receive(expects, done, true);
        return send('graph', 'addinport', {
          public: 'in',
          node: 'RepeatRenamed',
          port: 'in',
          graph: 'foo'
        }
        );
      }));
      // describe 'adding an in-port to a non-existent port', ->
      //   it "should return an error", (done) ->
      //     expects = [
      //       protocol: 'graph',
      //       command: 'error',
      //       payload:
      //         msg: 'Requested port not found'
      //     ]
      //     receive expects, done
      //     send 'graph', 'addinport',
      //       public: 'in'
      //       node: 'non-existent'
      //       port: 'in'
      //       graph: 'foo'
      describe('adding an out-port to a graph', () => it("should ACK", function(done) {
        const expects = [{
          protocol: 'graph',
          command: 'addoutport',
          payload: {
            graph: 'foo',
            node: 'RepeatRenamed',
            port: 'out',
            public: 'out'
          }
        }
        ];
        receive(expects, done, true);
        return send('graph', 'addoutport', {
          public: 'out',
          node: 'RepeatRenamed',
          port: 'out',
          graph: 'foo'
        }
        );
      }));
      // describe 'renaming an in-port of a graph', ->
      //   it "should provide the graph's ports back", (done) ->
      //     expects = [
      //       protocol: 'runtime',
      //       command: 'ports',
      //       payload:
      //         graph: 'foo'
      //         inPorts:
      //           [
      //             addressable: false
      //             id: "input"
      //             required: false
      //             type: "any"
      //           ]
      //         outPorts:
      //           [
      //             addressable: false
      //             id: "out"
      //             required: false
      //             type: "any"
      //           ]
      //     ]
      //     receive expects, done
      //     send 'graph', 'renameinport',
      //       from: 'in'
      //       to: 'input'
      //       graph: 'foo'
      return describe('removing an out-port of a graph', () => it("should ACK", function(done) {
        const expects = [{
          protocol: 'graph',
          command: 'removeoutport',
          payload: {
            graph: 'foo',
            public: 'out'
          }
        }
        ];
        receive(expects, done, true);
        return send('graph', 'removeoutport', {
          public: 'out',
          graph: 'foo'
        }
        );
      }));
    });
      // TODO:
      // ports:
      //   removeinport
      //   renameoutport
      // groups:
      //   addgroup / removegroup / renamegroup / changegroup

    describe('Network Protocol', function() {
      // Set up a clean graph
      before(function(done) {
        chai.expect(connection, 'Connection needs to be available').not.be.a('null');
        chai.expect(capabilities, 'Network protocol should be allowed for user').to.contain('protocol:network');
        let waitFor = 5;  // set this to the number of commands below
        var listener = function(message) {
          waitFor--;
          if (waitFor) {
            return connection.once('message', listener);
          } else {
            return done();
          }
        };
        connection.once('message', listener);
        send('graph', 'clear', {
          baseDir: path.resolve(__dirname, '../'),
          id: 'bar',
          main: true
        }
        );
        send('graph', 'addnode', {
          id: 'Hello',
          component: `${collection}/Repeat`,
          metadata: {},
          graph: 'bar'
        }
        );
        send('graph', 'addnode', {
          id: 'World',
          component: `${collection}/Drop`,
          metadata: {},
          graph: 'bar'
        }
        );
        send('graph', 'addedge', {
          src: {
            node: 'Hello',
            port: 'out'
          },
          tgt: {
            node: 'World',
            port: 'in'
          },
          graph: 'bar'
        }
        );
        return send('graph', 'addinitial', {
          src: {
            data: 'Hello, world!'
          },
          tgt: {
            node: 'Hello',
            port: 'in'
          },
          graph: 'bar'
        }
        );
      });

      describe('on starting the network', function() {
        it('should process the nodes and stop when it completes', function(done) {
          const expects = [{
            protocol: 'network',
            command: 'started',
            payload: {
              graph: 'bar',
              started: true,
              running: true,
              time: String
            }
          }
          , {
            protocol: 'network',
            command: 'data',
            payload: {
               id: 'DATA -> IN Hello()',
               graph: 'bar',
               tgt: { node: 'Hello', port: 'in' },
               data: 'Hello, world!'
             }
          }
          , {
            protocol: 'network',
            command: 'data',
            payload: {
               id: 'Hello() OUT -> IN World()',
               graph: 'bar',
               src: { node: 'Hello', port: 'out' },
               tgt: { node: 'World', port: 'in' },
               data: 'Hello, world!'
             }
          }
          ];
          receive(expects, done, true);
          return send('network', 'start',
            {graph: 'bar'});
        });

        return it("should provide a 'started' status", function(done) {
          const expects = [{
            protocol: 'network',
            command: 'status',
            payload: {
              graph: 'bar',
              running: false,
              started: true
            }
          }
          ];
          receive(expects, done, true);
          return send('network', 'getstatus',
            {graph: 'bar'});
        });
      });
      return describe('on stopping the network', function() {
        it('should be stopped', function(done) {
          const expects = [{
            protocol: 'network',
            command: 'stopped',
            payload: {
              graph: 'bar',
              running: false,
              started: false
            }
          }
          ];
          receive(expects, done, true);
          return send('network', 'stop',
            {graph: 'bar'});
        });

        return it("should provide a 'stopped' status", function(done) {
          const expects = [{
            protocol: 'network',
            command: 'status',
            payload: {
              graph: 'bar',
              running: false,
              started: false
            }
          }
          ];
          receive(expects, done, true);
          return send('network', 'getstatus',
            {graph: 'bar'});
        });
      });
    });
      // describe 'on console output', ->
      //   it 'should be able to capture and transmit it', (done) ->
      //     listener = (message) ->
      //       check done, ->
      //         rt.stopCapture()
      //         chai.expect(message.utf8Data).to.be.a 'string'
      //         msg = JSON.parse message.utf8Data
      //         chai.expect(msg.protocol).to.equal 'network'
      //         chai.expect(msg.command).to.equal 'output'
      //         chai.expect(msg.payload).to.be.an 'object'
      //         chai.expect(msg.payload.message).to.equal 'Hello, World!'
      //         done()
      //     connection.once 'message', listener
      //     rt.startCapture()
      //     console.log 'Hello, World!'

    return describe('Component Protocol', function() {
      before(function() {
        chai.expect(connection, 'Connection needs to be available').not.be.a('null');
        return chai.expect(capabilities, 'Component protocol should be allowed for connection').to.contain('protocol:component');
      });
      return describe('on requesting a component list', () => it('should receive some known components', function(done) {
        this.timeout(20000);
        var listener = function(message) {
          const data = JSON.parse(message.utf8Data);
          validateSchema(data, '/component/output/list');

          if (data.payload.name === `${collection}/Repeat`) {
            return done();
          } else {
            return connection.once('message', listener);
          }
        };


        connection.once('message', listener);

        return send('component', 'list', {});
    }));
  });
});
};

      // TODO:
      // getsource => source

exports.testRuntimeCommand = function(runtimeType, command=null, host, port, collection, version) {
  if (host == null) { host = 'localhost'; }
  if (port == null) { port = 8080; }
  if (collection == null) { collection = 'core'; }
  if (version == null) { version = '0.7'; }
  let child = null;
  const prefix = '      ';
  return exports.testRuntime( runtimeType,
    function(done) {
      if (!command) {
        console.log(`${prefix}not running a command. runtime is assumed to be started`);
        done();
        return;
      }
      console.log(`${prefix}\"${command}\" starting`);
      let returned = false;
      child = spawn(command, [], {
        cwd: process.cwd(),
        shell: true,
        stdio: [
          'ignore',
          'pipe',
          'ignore'
        ]
      });
      child.once('error', function(err) {
        child = null;
        if (returned) { return; }
        returned = true;
        return done(err);
      });
      child.stdout.once('data', function(data) {
        console.log(`${prefix}\"${command}\" has started`);
        return setTimeout(function() {
          if (returned) { return; }
          returned = true;
          return done();
        }
        , 100);
      });
      return child.once('close', function() {
        console.log(`${prefix}\"${command}\" exited`);
        child = null;
        if (returned) { return; }
        returned = true;
        return done(new Error('Child exited'));
      });
    },
    function(done) {
      if (!child) { return done(); }
      child.once('close', () => done());
      child.stdout.destroy();
      child.kill();
      return setTimeout(function() {
        // If SIGTERM didn't do it, try harder
        if (!child) { return; }
        return child.kill('SIGKILL');
      }
      , 100);
    },
    host,
    port,
    collection,
    version
  );
};
