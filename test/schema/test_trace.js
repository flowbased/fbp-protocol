const chai = require('chai');
const tv4 = require('tv4');
const uuid = require('uuid').v4;
const schemas = require('../../schema/schemas.js');

const validExamples = {
  'start recording': {
    protocol: 'trace',
    command: 'start',
    payload: {
      graph: 'mygraph',
    },
    secret: 'verygood',
    requestId: uuid(),
  },
  'dump flowtrace.json': {
    protocol: 'trace',
    command: 'dump',
    payload: {
      graph: 'mygraph',
      type: 'flowtrace.json',
    },
    secret: 'verygood',
    requestId: uuid(),
  },
  'clear buffer': {
    protocol: 'trace',
    command: 'clear',
    payload: {
      graph: 'mygraph',
    },
    secret: 'verygood',
    requestId: uuid(),
  },
  'stop recording': {
    protocol: 'trace',
    command: 'stop',
    payload: {
      graph: 'mygraph',
    },
    secret: 'verygood',
    requestId: uuid(),
  },
};

const invalidExamples = {
  'start with invalid graph id': {
    protocol: 'trace',
    command: 'start',
    payload: {
      graph: 112.0,
    },
    secret: 'nnice',
    requestId: uuid(),
  },
  'dump with invalid type': {
    protocol: 'trace',
    command: 'dump',
    payload: {
      graph: 'mygraph',
      type: 'not-a-valid-trace-type',
    },
    secret: 'verygood',
    requestId: uuid(),
  },
  'stop with missing secret': {
    protocol: 'trace',
    command: 'start',
    payload: {
      graph: 112.0,
    },
    secret: undefined,
    requestId: uuid(),
  },
  'clear without graph': {
    protocol: 'trace',
    command: 'start',
    payload: {
      graph: undefined,
    },
    secret: 'verygood',
    requestId: uuid(),
  },
};

const testValid = (name) => describe(name, () => it('should validate OK', () => {
  const data = validExamples[name];
  const schemaId = `/${data.protocol}/input/${data.command}`;
  const schema = tv4.getSchema(schemaId);
  // console.log 's', schemaId, JSON.stringify(schema, null, 2)
  const result = tv4.validateMultiple(data, schema);
  chai.expect(result.missing, `missing schemas ${result.missing}`).to.eql([]);
  chai.expect(result.errors, result.errors).to.eql([]);
}));

const testInvalid = (name) => describe(name, () => it('should error', () => {
  const data = invalidExamples[name];
  const schemaId = `/${data.protocol}/input/${data.command}`;
  const schema = tv4.getSchema(schemaId);
  const result = tv4.validateMultiple(data, schema);
  chai.expect(result.valid).to.equal(false);
}));

describe('Tracing protocol schema', () => {
  let traceSchema = null;
  before(() => {
    const sharedSchema = schemas.shared;
    traceSchema = schemas.trace;
    tv4.addSchema('/shared/', sharedSchema);
    tv4.addSchema('/trace/', traceSchema);
  });

  it('should exist', () => {
    chai.expect(traceSchema).to.be.an('object');
    chai.expect(traceSchema.input).to.be.an('object');
    chai.expect(traceSchema.output).to.be.an('object');
  });

  // generate the data-driven testcases
  describe('valid examples', () => Object.keys(validExamples).forEach((k) => testValid(k)));
  describe('invalid examples', () => Object.keys(invalidExamples).forEach((k) => testInvalid(k)));
});
