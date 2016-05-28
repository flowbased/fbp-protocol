(function() {
  var chai, fs, tv4;

  chai = require('chai');

  fs = require('fs');

  tv4 = require('tv4');

  describe('Test runtime protocol schema on event', function() {
    before(function() {
      var runtimeSchema, sharedSchema;
      sharedSchema = JSON.parse(fs.readFileSync('./schema/json/shared.json'));
      runtimeSchema = JSON.parse(fs.readFileSync('./schema/json/runtime.json'));
      tv4.addSchema('/shared/', sharedSchema);
      return tv4.addSchema('/runtime/', runtimeSchema);
    });
    describe('input', function() {
      describe('error', function() {
        var schema;
        schema = '/runtime/input/error';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'runtime',
            command: 'error',
            payload: {}
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
      describe('getruntime', function() {
        var schema;
        schema = '/runtime/input/getruntime';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'runtime',
            command: 'getruntime',
            payload: {}
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
      return describe('packet', function() {
        var schema;
        schema = '/runtime/input/packet';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'runtime',
            command: 'packet',
            payload: {
              port: 'IN',
              graph: 'mygraph',
              event: 'connect'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
        return it('should invalidate event with invalid enum choice', function() {
          var event, res;
          event = {
            protocol: 'runtime',
            command: 'packet',
            payload: {
              port: 'IN',
              graph: 'mygraph',
              event: 'bad event'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["false"];
        });
      });
    });
    return describe('output', function() {
      describe('error', function() {
        var schema;
        schema = '/runtime/output/error';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'runtime',
            command: 'error',
            payload: {}
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
      describe('ports', function() {
        var schema;
        schema = '/runtime/output/ports';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'runtime',
            command: 'ports',
            payload: {
              graph: 'mygraph',
              inPorts: [
                {
                  id: 'IN',
                  addressable: true,
                  type: 'string'
                }
              ],
              outPorts: []
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
      return describe('runtime', function() {
        var schema;
        schema = '/runtime/output/runtime';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'runtime',
            command: 'runtime',
            payload: {
              version: '0.2',
              capabilities: ['protocol:network', 'protocol:runtime', 'network:persist'],
              type: 'noflo'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
    });
  });

}).call(this);
