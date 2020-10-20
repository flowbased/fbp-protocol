const chai = require('chai');
const tv4 = require('tv4');
const uuid = require('uuid').v4;
const schemas = require('../../schema/schemas.js');

describe('Test runtime protocol schema on event', () => {
  before(() => {
    const sharedSchema = schemas.shared;
    const runtimeSchema = schemas.runtime;
    tv4.addSchema('/shared/', sharedSchema);
    tv4.addSchema('/runtime/', runtimeSchema);
  });

  describe('input', () => {
    describe('getruntime', () => {
      const schema = '/runtime/input/getruntime';

      it('should have schema', () => chai.expect(tv4.getSchema(schema)).to.exist);

      it('should validate event with required fields', () => {
        const event = {
          protocol: 'runtime',
          command: 'getruntime',
          payload: {},
          requestId: uuid(),
        };

        const res = tv4.validate(event, schema);
        chai.expect(res).to.equal(true);
      });
    });

    describe('packet', () => {
      const schema = '/runtime/input/packet';

      it('should have schema', () => chai.expect(tv4.getSchema(schema)).to.exist);

      it('should validate event with required fields', () => {
        const event = {
          protocol: 'runtime',
          command: 'packet',
          payload: {
            port: 'IN',
            graph: 'mygraph',
            event: 'connect',
          },
          requestId: uuid(),
        };

        const res = tv4.validate(event, schema);
        chai.expect(res).to.equal(true);
      });

      it('should invalidate event with invalid enum choice', () => {
        const event = {
          protocol: 'runtime',
          command: 'packet',
          payload: {
            port: 'IN',
            graph: 'mygraph',
            event: 'bad event',
          },
          requestId: uuid(),
        };

        const res = tv4.validate(event, schema);
        chai.expect(res).to.equal(false);
      });
    });
  });

  describe('output', () => {
    describe('error', () => {
      const schema = '/runtime/output/error';

      it('should have schema', () => chai.expect(tv4.getSchema(schema)).to.exist);

      it('should validate event with required fields', () => {
        const event = {
          protocol: 'runtime',
          command: 'error',
          payload: {
            message: 'inport "foo" for runtime:packet does not exist',
          },
        };

        const res = tv4.validate(event, schema);
        chai.expect(res).to.equal(true);
      });
    });

    describe('ports', () => {
      const schema = '/runtime/output/ports';

      it('should have schema', () => chai.expect(tv4.getSchema(schema)).to.exist);

      it('should validate event with required fields', () => {
        const event = {
          protocol: 'runtime',
          command: 'ports',
          payload: {
            graph: 'mygraph',
            inPorts: [{
              id: 'IN',
              addressable: true,
              type: 'string',
            },
            ],
            outPorts: [],
          },
        };

        const res = tv4.validate(event, schema);
        chai.expect(res).to.equal(true);
      });
    });

    describe('runtime', () => {
      const schema = '/runtime/output/runtime';

      it('should have schema', () => chai.expect(tv4.getSchema(schema)).to.exist);

      it('should validate event with required fields', () => {
        const event = {
          protocol: 'runtime',
          command: 'runtime',
          payload: {
            version: '0.2',
            capabilities: [
              'protocol:network',
              'protocol:runtime',
              'network:persist',
            ],
            type: 'noflo',
          },
        };

        const res = tv4.validate(event, schema);
        chai.expect(res).to.equal(true);
      });
    });
  });
});
