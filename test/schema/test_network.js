(function() {
  var chai, format, fs, tv4;

  chai = require('chai');

  fs = require('fs');

  tv4 = require('tv4');

  format = require('../../schema/format');

  describe('Test network protocol schema on events', function() {
    before(function() {
      var networkSchema, sharedSchema;
      sharedSchema = JSON.parse(fs.readFileSync('./schema/json/shared.json'));
      networkSchema = JSON.parse(fs.readFileSync('./schema/json/network.json'));
      tv4.addSchema('/shared/', sharedSchema);
      tv4.addSchema('/network/', networkSchema);
      return format(tv4);
    });
    describe('output', function() {
      describe('stopped', function() {
        var schema;
        schema = '/network/output/stopped';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'network',
            command: 'stopped',
            payload: {
              time: '2016-05-29 13:26:01Z-1:00',
              uptime: 1000,
              graph: 'mygraph'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
        it('should invalidate event with invalid date', function() {
          var event, res;
          event = {
            protocol: 'network',
            command: 'stopped',
            payload: {
              time: '5:00PM',
              uptime: 1000,
              graph: 'mygraph'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["false"];
        });
        return it('should invalidate event with extra fields', function() {
          var event, res;
          event = {
            hello: true,
            protocol: 'network',
            command: 'stopped',
            payload: {
              time: '5:00PM',
              uptime: 1000,
              graph: 'mygraph'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["false"];
        });
      });
      describe('started', function() {
        var schema;
        schema = '/network/output/started';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'network',
            command: 'started',
            payload: {
              time: '2016-05-29T13:26:01Z+1:00',
              graph: 'mygraph'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
      describe('status', function() {
        var schema;
        schema = '/network/output/status';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'network',
            command: 'status',
            payload: {
              running: true,
              uptime: 1000,
              graph: 'mygraph'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
      describe('output', function() {
        var schema;
        schema = '/network/output/output';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'network',
            command: 'output',
            payload: {
              message: 'hello',
              type: 'message'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
        return it('should invalidate event with invalid type', function() {
          var event, res;
          event = {
            protocol: 'network',
            command: 'output',
            payload: {
              message: 'hello',
              type: 'hello'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["false"];
        });
      });
      describe('error', function() {
        var schema;
        schema = '/network/output/error';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'network',
            command: 'error',
            payload: {
              message: 'oops'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
      describe('icon', function() {
        var schema;
        schema = '/network/output/icon';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'network',
            command: 'icon',
            payload: {
              id: 'node1',
              icon: 'amazingicon',
              graph: 'mygraph'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
      describe('connect', function() {
        var schema;
        schema = '/network/output/connect';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'network',
            command: 'connect',
            payload: {
              id: 'node1 OUT -> IN node2',
              src: {
                process: 'node1',
                port: 'out'
              },
              tgt: {
                process: 'node2',
                port: 'in'
              },
              graph: 'mygraph'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
      describe('begingroup', function() {
        var schema;
        schema = '/network/output/begingroup';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'network',
            command: 'begingroup',
            payload: {
              id: 'node1 OUT -> IN node2',
              src: {
                process: 'node1',
                port: 'out'
              },
              tgt: {
                process: 'node2',
                port: 'in'
              },
              group: 'group1',
              graph: 'mygraph'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
        it('should invalidate event without required fields', function() {
          var event, res;
          event = {
            protocol: 'network',
            command: 'begingroup',
            payload: {
              id: 'node1 OUT -> IN node2',
              src: {
                process: 'node1',
                port: 'out'
              },
              tgt: {
                process: 'node2',
                port: 'in'
              },
              graph: 'mygraph'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["false"];
        });
        return it('should invalidate event with extra fields', function() {
          var event, res;
          event = {
            protocol: 'network',
            command: 'begingroup',
            payload: {
              id: 'node1 OUT -> IN node2',
              src: {
                process: 'node1',
                port: 'out'
              },
              tgt: {
                process: 'node2',
                port: 'in'
              },
              group: 'group1',
              graph: 'mygraph',
              extra: 'test'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["false"];
        });
      });
      describe('data', function() {
        var schema;
        schema = '/network/output/data';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'network',
            command: 'data',
            payload: {
              id: 'node1 OUT -> IN node2',
              src: {
                process: 'node1',
                port: 'out'
              },
              tgt: {
                process: 'node2',
                port: 'in'
              },
              data: 5,
              graph: 'mygraph'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
      describe('endgroup', function() {
        var schema;
        schema = '/network/output/endgroup';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'network',
            command: 'endgroup',
            payload: {
              id: 'node1 OUT -> IN node2',
              src: {
                process: 'node1',
                port: 'out'
              },
              tgt: {
                process: 'node2',
                port: 'in'
              },
              group: 'group1',
              graph: 'mygraph'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
      return describe('disconnect', function() {
        var schema;
        schema = '/network/output/disconnect';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'network',
            command: 'disconnect',
            payload: {
              id: 'node1 OUT -> IN node2',
              src: {
                process: 'node1',
                port: 'out'
              },
              tgt: {
                process: 'node2',
                port: 'in'
              },
              graph: 'mygraph'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
    });
    return describe('input', function() {
      describe('error', function() {
        var schema;
        schema = '/network/input/error';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'network',
            command: 'error',
            payload: {}
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
      describe('start', function() {
        var schema;
        schema = '/network/input/start';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'network',
            command: 'start',
            payload: {
              graph: 'start'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
      describe('getstatus', function() {
        var schema;
        schema = '/network/input/getstatus';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'network',
            command: 'getstatus',
            payload: {
              graph: 'mygraph'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
      describe('getstatus', function() {
        var schema;
        schema = '/network/input/getstatus';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'network',
            command: 'getstatus',
            payload: {
              graph: 'mygraph'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
      describe('stop', function() {
        var schema;
        schema = '/network/input/stop';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'network',
            command: 'stop',
            payload: {
              graph: 'mygraph'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
      return describe('edges', function() {
        var schema;
        schema = '/network/input/edges';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'network',
            command: 'edges',
            payload: {
              edges: [
                {
                  src: {
                    process: 'node1',
                    port: 'OUT'
                  },
                  tgt: {
                    process: 'node2',
                    port: 'IN',
                    index: 0
                  }
                }
              ]
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
    });
  });

}).call(this);
