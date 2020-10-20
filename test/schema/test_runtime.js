/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const chai = require('chai');
const schemas = require('../../schema/schemas.js');
const tv4 = require('tv4');
const uuid = require('uuid').v4;

describe('Test runtime protocol schema on event', function() {
  before(function() {
    const sharedSchema = schemas.shared;
    const runtimeSchema = schemas.runtime;
    tv4.addSchema('/shared/', sharedSchema);
    return tv4.addSchema('/runtime/', runtimeSchema);
  });

  describe('input', function() {

    describe('getruntime', function() {
      const schema = '/runtime/input/getruntime';

      it('should have schema', () => chai.expect(tv4.getSchema(schema)).to.exist);

      return it('should validate event with required fields', function() {
        const event = {
          protocol: 'runtime',
          command: 'getruntime',
          payload: {},
          requestId: uuid()
        };

        const res = tv4.validate(event, schema);
        return chai.expect(res).to.be.true;
      });
    });

    return describe('packet', function() {
      const schema = '/runtime/input/packet';

      it('should have schema', () => chai.expect(tv4.getSchema(schema)).to.exist);

      it('should validate event with required fields', function() {
        const event = {
          protocol: 'runtime',
          command: 'packet',
          payload: {
            port: 'IN',
            graph: 'mygraph',
            event: 'connect'
          },
          requestId: uuid()
        };

        const res = tv4.validate(event, schema);
        return chai.expect(res).to.be.true;
      });

      return it('should invalidate event with invalid enum choice', function() {
        const event = {
          protocol: 'runtime',
          command: 'packet',
          payload: {
            port: 'IN',
            graph: 'mygraph',
            event: 'bad event'
          },
          requestId: uuid()
        };

        const res = tv4.validate(event, schema);
        return chai.expect(res).to.be.false;
      });
    });
  });

  return describe('output', function() {
    describe('error', function() {
      const schema = '/runtime/output/error';

      it('should have schema', () => chai.expect(tv4.getSchema(schema)).to.exist);

      return it('should validate event with required fields', function() {
        const event = {
          protocol: 'runtime',
          command: 'error',
          payload: {
            message: 'inport "foo" for runtime:packet does not exist'
          }
        };

        const res = tv4.validate(event, schema);
        return chai.expect(res).to.be.true;
      });
    });

    describe('ports', function() {
      const schema = '/runtime/output/ports';

      it('should have schema', () => chai.expect(tv4.getSchema(schema)).to.exist);

      return it('should validate event with required fields', function() {
        const event = {
          protocol: 'runtime',
          command: 'ports',
          payload: {
            graph: 'mygraph',
            inPorts: [{
              id: 'IN',
              addressable: true,
              type: 'string'
            }
            ],
            outPorts: []
          }
        };

        const res = tv4.validate(event, schema);
        return chai.expect(res).to.be.true;
      });
    });

    return describe('runtime', function() {
      const schema = '/runtime/output/runtime';

      it('should have schema', () => chai.expect(tv4.getSchema(schema)).to.exist);

      return it('should validate event with required fields', function() {
        const event = {
          protocol: 'runtime',
          command: 'runtime',
          payload: {
            version: '0.2',
            capabilities: [
              'protocol:network',
              'protocol:runtime',
              'network:persist'
            ],
            type: 'noflo'
          }
        };

        const res = tv4.validate(event, schema);
        return chai.expect(res).to.be.true;
      });
    });
  });
});

