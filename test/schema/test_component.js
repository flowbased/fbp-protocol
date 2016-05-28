(function() {
  var chai, fs, tv4;

  chai = require('chai');

  fs = require('fs');

  tv4 = require('tv4');

  describe('Test component protocol schema on event', function() {
    before(function() {
      var componentSchema, sharedSchema;
      sharedSchema = JSON.parse(fs.readFileSync('./schema/json/shared.json'));
      componentSchema = JSON.parse(fs.readFileSync('./schema/json/component.json'));
      tv4.addSchema('/shared/', sharedSchema);
      return tv4.addSchema('/component/', componentSchema);
    });
    describe('output', function() {
      describe('error', function() {
        var schema;
        schema = '/component/output/error';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'component',
            command: 'error',
            payload: {}
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
      describe('component', function() {
        var schema;
        schema = '/component/output/component';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'component',
            command: 'component',
            payload: {
              name: 'mycomponent',
              subgraph: false,
              inPorts: [],
              outPorts: []
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
      return describe('source', function() {
        var schema;
        schema = '/component/output/source';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'component',
            command: 'source',
            payload: {
              name: 'component1',
              language: 'coffeescript',
              code: '-> console.log Array.prototype.slice.call arguments'
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
        schema = '/component/input/error';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'component',
            command: 'error',
            payload: {}
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
      describe('list', function() {
        var schema;
        schema = '/component/input/list';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'component',
            command: 'list',
            payload: {}
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
      describe('getsource', function() {
        var schema;
        schema = '/component/input/getsource';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'component',
            command: 'getsource',
            payload: {
              name: 'component1'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
      return describe('source', function() {
        var schema;
        schema = '/component/input/source';
        it('should have schema', function() {
          return chai.expect(tv4.getSchema(schema)).to.exist;
        });
        return it('should validate event with required fields', function() {
          var event, res;
          event = {
            protocol: 'component',
            command: 'source',
            payload: {
              name: 'component1',
              language: 'coffeescript',
              code: '-> console.log Array.prototype.slice.call arguments'
            }
          };
          res = tv4.validate(event, schema);
          return chai.expect(res).to.be["true"];
        });
      });
    });
  });

}).call(this);
