/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const chai = require('chai');
const schemas = require('../../schema/schemas.js');
const tv4 = require('tv4');
const uuid = require('uuid').v4;

describe('Test component protocol schema on event', function() {
  before(function() {
    const sharedSchema = schemas.shared;
    const componentSchema = schemas.component;
    tv4.addSchema('/shared/', sharedSchema);
    return tv4.addSchema('/component/', componentSchema);
  });

  describe('output', function() {
    describe('error', function() {
      const schema = '/component/output/error';

      it('should have schema', () => chai.expect(tv4.getSchema(schema)).to.exist);

      return it('should validate event with required fields', function() {
        const event = {
          protocol: 'component',
          command: 'error',
          payload: {
            message: "component failed to compile, line fofof:33"
          }
        };

        const res = tv4.validateMultiple(event, schema);
        chai.expect(res.missing).to.eql([]);
        chai.expect(res.errors).to.eql([]);
        return chai.expect(res.valid).to.equal(true);
      });
    });

    describe('component', function() {
      const schema = '/component/output/component';

      it('should have schema', () => chai.expect(tv4.getSchema(schema)).to.exist);

      return it('should validate event with required fields', function() {
        const event = {
          protocol: 'component',
          command: 'component',
          payload: {
            name: 'mycomponent',
            subgraph: false,
            inPorts: [],
            outPorts: []
          }
        };

        const res = tv4.validate(event, schema);
        return chai.expect(res).to.be.true;
      });
    });

    return describe('source', function() {
      const schema = '/component/output/source';

      it('should have schema', () => chai.expect(tv4.getSchema(schema)).to.exist);

      return it('should validate event with required fields', function() {
        const event = {
          protocol: 'component',
          command: 'source',
          payload: {
            name: 'component1',
            language: 'coffeescript',
            code: '-> console.log Array.prototype.slice.call arguments'
          }
        };

        const res = tv4.validate(event, schema);
        return chai.expect(res).to.be.true;
      });
    });
  });

  return describe('input', function() {

    describe('list', function() {
      const schema = '/component/input/list';

      it('should have schema', () => chai.expect(tv4.getSchema(schema)).to.exist);

      return it('should validate event with required fields', function() {
        const event = {
          protocol: 'component',
          command: 'list',
          payload: {},
          requestId: uuid()
        };

        const res = tv4.validate(event, schema);
        return chai.expect(res).to.be.true;
      });
    });

    describe('getsource', function() {
      const schema = '/component/input/getsource';

      it('should have schema', () => chai.expect(tv4.getSchema(schema)).to.exist);

      return it('should validate event with required fields', function() {
        const event = {
          protocol: 'component',
          command: 'getsource',
          payload: {
            name: 'component1'
          },
          requestId: uuid()
        };

        const res = tv4.validate(event, schema);
        return chai.expect(res).to.be.true;
      });
    });

    return describe('source', function() {
      const schema = '/component/input/source';

      it('should have schema', () => chai.expect(tv4.getSchema(schema)).to.exist);

      return it('should validate event with required fields', function() {
        const event = {
          protocol: 'component',
          command: 'source',
          payload: {
            name: 'component1',
            language: 'coffeescript',
            code: '-> console.log Array.prototype.slice.call arguments'
          },
          requestId: uuid()
        };

        const res = tv4.validate(event, schema);
        return chai.expect(res).to.be.true;
      });
    });
  });
});
