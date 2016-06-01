(function() {
  var WebSocketClient, chai, check, path, semver, shelljs, tv4;

  chai = require('chai');

  path = require('path');

  shelljs = require('shelljs');

  WebSocketClient = require('websocket').client;

  semver = require('semver');

  tv4 = require('../schema/index.js');

  check = function(done, f) {
    var e;
    try {
      return f();
    } catch (_error) {
      e = _error;
      return done(e);
    }
  };

  exports.testRuntime = function(runtimeType, startServer, stopServer, host, port, collection, version) {
    var address, semanticVersion;
    if (host == null) {
      host = 'localhost';
    }
    if (port == null) {
      port = 8080;
    }
    if (collection == null) {
      collection = 'core';
    }
    if (version == null) {
      version = '0.5';
    }
    if (version.length === 3) {
      semanticVersion = "" + version + ".0";
    } else {
      semanticVersion = version;
    }
    address = "ws://" + host + ":" + port + "/";
    return describe("" + runtimeType + " webSocket network runtime version " + version, function() {
      var client, connection, receive, send;
      client = null;
      connection = null;
      send = null;
      describe("Connecting to the runtime at " + address, function() {
        return it('should succeed', function(done) {
          var tries;
          this.timeout(4000);
          tries = 10;
          return startServer(function() {
            client = new WebSocketClient;
            client.on('connect', function(conn) {
              connection = conn;
              connection.setMaxListeners(1000);
              return done();
            });
            client.on('connectFailed', function(err) {
              tries--;
              chai.expect(tries).to.be.above(0);
              return setTimeout(function() {
                return client.connect(address, 'noflo');
              }, 200);
            });
            return client.connect(address, 'noflo');
          });
        });
      });
      after(stopServer);
      send = function(protocol, command, payload) {
        if (!payload) {
          payload = {};
        }
        if (process.env.FBP_PROTOCOL_SECRET) {
          payload.secret = process.env.FBP_PROTOCOL_SECRET;
        }
        return connection.sendUTF(JSON.stringify({
          protocol: protocol,
          command: command,
          payload: payload
        }));
      };
      receive = function(expects, done, ignore) {
        var listener;
        if (ignore == null) {
          ignore = null;
        }
        listener = function(message) {
          return check(done, function() {
            var expected, key, msg, type, value, _ref;
            chai.expect(message.utf8Data).to.be.a('string');
            msg = JSON.parse(message.utf8Data);
            if (!ignore || !ignore(msg)) {
              expected = expects.shift();
              chai.expect(msg.protocol, 'protocol').to.equal(expected.protocol);
              chai.expect(msg.command, 'command').to.equal(expected.command);
              if (expected.payload) {
                _ref = expected.payload;
                for (key in _ref) {
                  value = _ref[key];
                  type = null;
                  if (value === String) {
                    type = 'string';
                  } else if (value === Number) {
                    type = 'number';
                  } else if (value === Array) {
                    type = 'array';
                  }
                  if (type) {
                    chai.expect(msg.payload, "payload." + key).to.exist;
                    chai.expect(msg.payload[key], "payload." + key).to.be.a(type);
                    delete expected.payload[key];
                    delete msg.payload[key];
                  }
                }
              }
              chai.expect(msg).to.eql(expected);
            }
            if (expects.length) {
              return connection.once('message', listener);
            } else {
              return done();
            }
          });
        };
        return connection.once('message', listener);
      };
      describe('Runtime Protocol', function() {
        return describe('requesting runtime metadata', function() {
          return it('should provide it back', function(done) {
            connection.once('message', function(message) {
              var data;
              data = message.utf8Data;
              chai.expect(tv4.validate(data, '/runtime/output/runtime')).to.be["true"];
              return done();
            });
            return send('runtime', 'getruntime', {});
          });
        });
      });
      describe('Graph Protocol', function() {
        describe('adding a graph and nodes', function() {
          return it('should provide the nodes back', function(done) {
            var expects;
            expects = [
              {
                protocol: 'graph',
                command: 'clear',
                payload: {
                  baseDir: path.resolve(__dirname, '../'),
                  id: 'foo',
                  main: true,
                  name: 'NoFlo runtime'
                }
              }, {
                protocol: 'graph',
                command: 'addnode',
                payload: {
                  id: 'Repeat1',
                  component: "" + collection + "/Repeat",
                  metadata: {
                    hello: 'World'
                  },
                  graph: 'foo'
                }
              }, {
                protocol: 'graph',
                command: 'addnode',
                payload: {
                  id: 'Drop1',
                  component: "" + collection + "/Drop",
                  metadata: {},
                  graph: 'foo'
                }
              }
            ];
            connection.once('message', function(message) {
              var data;
              data = JSON.parse(message.utf8Data);
              chai.expect(tv4.validate(data, '/graph/output/clear')).to.be["true"];
              connection.once('message', function(message) {
                data = JSON.parse(message.utf8Data);
                chai.expect(tv4.validate(data, '/graph/output/addnode')).to.be["true"];
                chai.expect(data.payload.id).to.equal(expects[1].payload.id);
                connection.once('message', function(message) {
                  data = JSON.parse(message.utf8Data);
                  chai.expect(tv4.validate(data, '/graph/output/addnode')).to.be["true"];
                  chai.expect(data.payload.id).to.equal(expects[2].payload.id);
                  return done();
                });
                return send('graph', 'addnode', expects[2].payload);
              });
              return send('graph', 'addnode', expects[1].payload);
            });
            return send('graph', 'clear', {
              baseDir: path.resolve(__dirname, '../'),
              id: 'foo',
              main: true
            });
          });
        });
        describe('adding an edge', function() {
          return it('should provide the edge back', function(done) {
            var expects;
            expects = [
              {
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
            connection.once('message', function(message) {
              var data;
              data = JSON.parse(message.utf8Data);
              chai.expect(tv4.validate(data, '/graph/output/addedge')).to.be["true"];
              chai.expect(data.payload.src).to.eql(expects[0].payload.src);
              chai.expect(data.payload.tgt).to.eql(expects[0].payload.tgt);
              return done();
            });
            return send('graph', 'addedge', expects[0].payload);
          });
        });
        describe('adding metadata', function() {
          describe('to a node with no metadata', function() {
            return it('should add the metadata', function(done) {
              var expects;
              expects = [
                {
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
              connection.once('message', function(message) {
                var data;
                data = JSON.parse(message.utf8Data);
                chai.expect(tv4.validate(data, '/graph/output/changenode')).to.be["true"];
                chai.expect(data.payload.metadata).to.eql(expects[0].payload.metadata);
                return done();
              });
              return send('graph', 'changenode', expects[0].payload);
            });
          });
          describe('to a node with existing metadata', function() {
            return it('should merge the metadata', function(done) {
              var expects;
              expects = [
                {
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
              connection.once('message', function(message) {
                var data;
                data = JSON.parse(message.utf8Data);
                chai.expect(tv4.validate(data, '/graph/output/changenode')).to.be["true"];
                chai.expect(data.payload.metadata).to.eql(expects[0].payload.metadata);
                return done();
              });
              return send('graph', 'changenode', {
                id: 'Drop1',
                metadata: {
                  tag: 'awesome'
                },
                graph: 'foo'
              });
            });
          });
          describe('with no keys to a node with existing metadata', function() {
            return it('should not change the metadata', function(done) {
              var expects;
              expects = [
                {
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
              connection.once('message', function(message) {
                var data;
                data = JSON.parse(message.utf8Data);
                chai.expect(tv4.validate(data, '/graph/output/changenode')).to.be["true"];
                chai.expect(data.payload.metadata).to.eql(expects[0].payload.metadata);
                return done();
              });
              return send('graph', 'changenode', {
                id: 'Drop1',
                metadata: {},
                graph: 'foo'
              });
            });
          });
          return describe('with a null value removes it from the node', function() {
            return it('should merge the metadata', function(done) {
              var expects;
              expects = [
                {
                  protocol: 'graph',
                  command: 'changenode',
                  payload: {
                    id: 'Drop1',
                    metadata: {},
                    graph: 'foo'
                  }
                }
              ];
              connection.once('message', function(message) {
                var data;
                data = JSON.parse(message.utf8Data);
                chai.expect(tv4.validate(data, '/graph/output/changenode')).to.be["true"];
                chai.expect(data.payload.metadata).to.eql(expects[0].payload.metadata);
                return done();
              });
              return send('graph', 'changenode', {
                id: 'Drop1',
                metadata: {
                  sort: null,
                  tag: null
                },
                graph: 'foo'
              });
            });
          });
        });
        describe('adding an IIP', function() {
          return it('should provide the IIP back', function(done) {
            var expects;
            expects = [
              {
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
            connection.once('message', function(message) {
              var data;
              data = JSON.parse(message.utf8Data);
              chai.expect(tv4.validate(data, '/graph/output/addinitial')).to.be["true"];
              chai.expect(data.payload).to.eql(expects[0].payload);
              return done();
            });
            return send('graph', 'addinitial', expects[0].payload);
          });
        });
        describe('removing a node', function() {
          return it('should remove the node and its associated edges', function(done) {
            var expects;
            expects = [
              {
                protocol: 'graph',
                command: 'changeedge',
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
              }, {
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
                  metadata: {
                    route: 5
                  },
                  graph: 'foo'
                }
              }, {
                protocol: 'graph',
                command: 'changenode',
                payload: {
                  id: 'Drop1',
                  metadata: {},
                  graph: 'foo'
                }
              }, {
                protocol: 'graph',
                command: 'removenode',
                payload: {
                  id: 'Drop1',
                  component: "" + collection + "/Drop",
                  metadata: {},
                  graph: 'foo'
                }
              }
            ];
            connection.once('message', function(message) {
              var data;
              data = JSON.parse(message.utf8Data);
              chai.expect(tv4.validate(data, '/graph/output/removenode')).to.be["true"];
              chai.expect(data.payload).to.eql(expects[0].payload);
              return done();
            });
            return send('graph', 'removenode', {
              id: 'Drop1',
              graph: 'foo'
            });
          });
        });
        describe('removing an IIP', function() {
          return it('should provide response that iip was removed', function(done) {
            var expects;
            expects = [
              {
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
                  metadata: {},
                  graph: 'foo'
                }
              }
            ];
            connection.once('message', function(message) {
              var data;
              data = JSON.parse(message.utf8Data);
              chai.expect(tv4.validate(data, '/graph/output/removeinitial')).to.be["true"];
              chai.expect(data.payload.src).to.eql(expects[0].payload.src);
              return done();
            });
            return send('graph', 'removeinitial', {
              tgt: {
                node: 'Repeat1',
                port: 'in'
              },
              graph: 'foo'
            });
          });
        });
        describe('renaming a node', function() {
          return it('should send the renamenode event', function(done) {
            var expects;
            expects = [
              {
                protocol: 'graph',
                command: 'renamenode',
                payload: {
                  from: 'Repeat1',
                  to: 'RepeatRenamed',
                  graph: 'foo'
                }
              }
            ];
            connection.once('message', function(message) {
              var data;
              data = JSON.parse(message.utf8Data);
              chai.expect(tv4.validate(data, '/graph/output/renamenode')).to.be["true"];
              chai.expect(data.payload).to.eql(expects[0].payload);
              return done();
            });
            return send('graph', 'renamenode', expects[0].payload);
          });
        });
        describe('adding a node to a non-existent graph', function() {
          return it('should send an error', function(done) {
            var expects;
            expects = [
              {
                protocol: 'graph',
                command: 'error',
                payload: {
                  message: 'Requested graph not found',
                  stack: String
                }
              }
            ];
            connection.once('message', function(message) {
              var data;
              data = JSON.parse(message.utf8Data);
              chai.expect(tv4.validate(data, '/graph/output/error')).to.be["true"];
              return done();
            });
            return send('graph', 'addnode', {
              id: 'Repeat1',
              component: "" + collection + "/Repeat",
              graph: 'another-graph'
            });
          });
        });
        describe('adding a node without specifying a graph', function() {
          return it('should send an error', function(done) {
            var expects;
            expects = [
              {
                protocol: 'graph',
                command: 'error',
                payload: {
                  message: 'No graph specified',
                  stack: String
                }
              }
            ];
            connection.once('message', function(message) {
              var data;
              data = JSON.parse(message.utf8Data);
              chai.expect(tv4.validate(data, '/graph/output/error')).to.be["true"];
              return done();
            });
            return send('graph', 'addnode', {
              id: 'Repeat1',
              component: "" + collection + "/Repeat"
            });
          });
        });
        describe('adding an in-port to a graph', function() {
          return it("should ACK", function(done) {
            var expects;
            expects = [
              {
                protocol: 'graph',
                command: 'addinport',
                payload: {
                  graph: 'foo',
                  node: 'RepeatRenamed',
                  "public": 'in',
                  port: 'in'
                }
              }
            ];
            connection.once('message', function(message) {
              var data;
              data = JSON.parse(message.utf8Data);
              chai.expect(tv4.validate(data, '/graph/output/addinport')).to.be["true"];
              chai.expect(data.payload).to.equal(expects[0].payload);
              return done();
            });
            return send('graph', 'addinport', {
              "public": 'in',
              node: 'RepeatRenamed',
              port: 'in',
              graph: 'foo'
            });
          });
        });
        describe('adding an out-port to a graph', function() {
          return it("should ACK", function(done) {
            var expects;
            expects = [
              {
                protocol: 'graph',
                command: 'addoutport',
                payload: {
                  graph: 'foo',
                  node: 'RepeatRenamed',
                  port: 'out',
                  "public": 'out'
                }
              }
            ];
            connection.once('message', function(message) {
              var data;
              data = JSON.parse(message.utf8Data);
              chai.expect(tv4.validate(data, '/graph/output/addoutport')).to.be["true"];
              chai.expect(data.payload).to.equal(expects[0].payload);
              return done();
            });
            return send('graph', 'addoutport', {
              "public": 'out',
              node: 'RepeatRenamed',
              port: 'out',
              graph: 'foo'
            });
          });
        });
        return describe('removing an out-port of a graph', function() {
          return it("should ACK", function(done) {
            var expects;
            expects = [
              {
                protocol: 'graph',
                command: 'removeoutport',
                payload: {
                  graph: 'foo',
                  "public": 'out'
                }
              }
            ];
            connection.once('message', function(message) {
              var data;
              data = JSON.parse(message.utf8Data);
              chai.expect(tv4.validate(data, '/graph/output/removeoutport')).to.be["true"];
              chai.expect(data.payload).to.equal(expects[0].payload);
              return done();
            });
            return send('graph', 'removeoutport', {
              "public": 'out',
              graph: 'foo'
            });
          });
        });
      });
      describe('Network protocol', function() {
        before(function(done) {
          var listener, waitFor;
          waitFor = 5;
          listener = function(message) {
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
          });
          send('graph', 'addnode', {
            id: 'Hello',
            component: "" + collection + "/Repeat",
            metadata: {},
            graph: 'bar'
          });
          send('graph', 'addnode', {
            id: 'World',
            component: "" + collection + "/Drop",
            metadata: {},
            graph: 'bar'
          });
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
          });
          return send('graph', 'addinitial', {
            src: {
              data: 'Hello, world!'
            },
            tgt: {
              node: 'Hello',
              port: 'in'
            },
            graph: 'bar'
          });
        });
        describe('on starting the network', function() {
          it('should process the nodes and stop when it completes', function(done) {
            var expects;
            expects = [
              {
                protocol: 'network',
                command: 'started',
                payload: {
                  graph: 'bar',
                  started: true,
                  running: true,
                  time: String
                }
              }, {
                protocol: 'network',
                command: 'connect',
                payload: {
                  id: 'DATA -> IN Hello()',
                  graph: 'bar',
                  tgt: {
                    node: 'Hello',
                    port: 'in'
                  }
                }
              }, {
                protocol: 'network',
                command: 'data',
                payload: {
                  id: 'DATA -> IN Hello()',
                  graph: 'bar',
                  tgt: {
                    node: 'Hello',
                    port: 'in'
                  },
                  data: 'Hello, world!'
                }
              }, {
                protocol: 'network',
                command: 'connect',
                payload: {
                  id: 'Hello() OUT -> IN World()',
                  graph: 'bar',
                  src: {
                    node: 'Hello',
                    port: 'out'
                  },
                  tgt: {
                    node: 'World',
                    port: 'in'
                  }
                }
              }, {
                protocol: 'network',
                command: 'data',
                payload: {
                  id: 'Hello() OUT -> IN World()',
                  graph: 'bar',
                  src: {
                    node: 'Hello',
                    port: 'out'
                  },
                  tgt: {
                    node: 'World',
                    port: 'in'
                  },
                  data: 'Hello, world!'
                }
              }, {
                protocol: 'network',
                command: 'disconnect',
                payload: {
                  id: 'DATA -> IN Hello()',
                  graph: 'bar',
                  tgt: {
                    node: 'Hello',
                    port: 'in'
                  }
                }
              }, {
                protocol: 'network',
                command: 'disconnect',
                payload: {
                  id: 'Hello() OUT -> IN World()',
                  graph: 'bar',
                  src: {
                    node: 'Hello',
                    port: 'out'
                  },
                  tgt: {
                    node: 'World',
                    port: 'in'
                  }
                }
              }
            ];
            connection.once('message', function(message) {
              var data;
              data = JSON.parse(message.utf8Data);
              chai.expect(tv4.validate(data, '/network/output/started')).to.be["true"];
              return done();
            });
            return send('network', 'start', {
              graph: 'bar'
            });
          });
          return it("should provide a 'started' status", function(done) {
            var expects;
            expects = [
              {
                protocol: 'network',
                command: 'status',
                payload: {
                  graph: 'bar',
                  running: false,
                  started: true
                }
              }
            ];
            connection.once('message', function(message) {
              var data;
              data = JSON.parse(message.utf8Data);
              chai.expect(tv4.validate(data, '/network/output/status')).to.be["true"];
              chai.expect(data.payload.started).to.be["true"];
              return done();
            });
            return send('network', 'getstatus', {
              graph: 'bar'
            });
          });
        });
        return describe('on stopping the network', function() {
          it('should be stopped', function(done) {
            var expects;
            expects = [
              {
                protocol: 'network',
                command: 'stopped',
                payload: {
                  graph: 'bar',
                  started: false,
                  running: false,
                  time: String,
                  uptime: Number
                }
              }
            ];
            connection.once('message', function(message) {
              var data;
              data = JSON.parse(message.utf8Data);
              chai.expect(tv4.validate(data, '/network/output/stopped')).to.be["true"];
              return done();
            });
            return send('network', 'stop', {
              graph: 'bar'
            });
          });
          return it("should provide a 'stopped' status", function(done) {
            var expects;
            expects = [
              {
                protocol: 'network',
                command: 'status',
                payload: {
                  graph: 'bar',
                  running: false,
                  started: false
                }
              }
            ];
            connection.once('message', function(message) {
              var data;
              data = JSON.parse(message.utf8Data);
              chai.expect(tv4.validate(data, '/network/output/stopped')).to.be["true"];
              chai.expect(data.payload.started).to.be["false"];
              chai.expect(data.payload.running).to.be["false"];
              return done();
            });
            return send('network', 'getstatus', {
              graph: 'bar'
            });
          });
        });
      });
      return describe('Component protocol', function() {
        return describe('on requesting a component list', function() {
          return it('should receive some known components', function(done) {
            var listener;
            listener = function(message) {
              var data;
              data = JSON.parse(message.utf8Data);
              chai.expect(tv4.validate(data, '/component/output/list')).to.be["true"];
              if (data.payload.name === ("" + collection + "/Repeat")) {
                return done();
              } else {
                return connection.once('message', listener);
              }
            };
            connection.once('message', listener);
            return send('component', 'list', collection);
          });
        });
      });
    });
  };

  exports.testRuntimeCommand = function(runtimeType, command, host, port, collection, version) {
    var child;
    if (command == null) {
      command = null;
    }
    if (host == null) {
      host = 'localhost';
    }
    if (port == null) {
      port = 8080;
    }
    if (collection == null) {
      collection = 'core';
    }
    if (version == null) {
      version = '0.5';
    }
    child = null;
    return exports.testRuntime(runtimeType, function(done) {
      if (command) {
        console.log("running '" + command + "'");
        child = shelljs.exec(command, {
          async: true
        });
      } else {
        console.log("not running a command. runtime is assumed to be started");
      }
      return done();
    }, function() {
      if (child) {
        return child.kill("SIGKILL");
      }
    }, host, port, collection, version);
  };

}).call(this);
