chai = require 'chai'
schemas = require '../../schema/schemas.js'
tv4 = require 'tv4'

validExamples =
  'typical start':
    protocol: 'trace'
    command: 'start'
    payload:
      graph: 'mygraph'
      secret: 'verygood'

invalidExamples =
  'invalid graph id':
    protocol: 'trace'
    command: 'start'
    payload:
      graph: 112.0
      secret: 'nnice'

testValid = (name) -> 
  describe name, ->
    it 'should validate OK', ->
      data = validExamples[name]
      schemaId = "/#{data.protocol}/input/#{data.command}"
      schema = tv4.getSchema schemaId
      #console.log 's', schemaId, JSON.stringify(schema, null, 2)
      result = tv4.validateMultiple data, schema
      chai.expect(result.missing, "missing schemas #{result.missing}").to.eql []
      chai.expect(result.errors, result.errors).to.eql []

testInvalid = (name) ->
  describe name, ->
    it 'should error', ->
      data = invalidExamples[name]
      schemaId = "/#{data.protocol}/input/#{data.command}"
      schema = tv4.getSchema schemaId
      result = tv4.validateMultiple data, schema
      chai.expect(result.valid).to.be.false

describe 'Tracing protocol schema', ->
  traceSchema = null
  before ->
    sharedSchema = schemas.shared
    traceSchema = schemas.trace
    tv4.addSchema '/shared/', sharedSchema
    tv4.addSchema '/trace/', traceSchema

  it 'should exist', ->
    chai.expect(traceSchema).to.exist
    chai.expect(traceSchema).to.be.an 'object'
    chai.expect(traceSchema.input).to.be.an 'object'
    chai.expect(traceSchema.output).to.be.an 'object'

  # generate the data-driven testcases
  describe 'valid examples', ->
    Object.keys(validExamples).forEach (k) -> testValid k
  describe 'invalid examples', ->
    Object.keys(invalidExamples).forEach (k) -> testInvalid k
