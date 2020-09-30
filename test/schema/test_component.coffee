chai = require 'chai'
schemas = require '../../schema/schemas.js'
tv4 = require 'tv4'
uuid = require('uuid').v4

describe 'Test component protocol schema on event', ->
  before ->
    sharedSchema = schemas.shared
    componentSchema = schemas.component
    tv4.addSchema '/shared/', sharedSchema
    tv4.addSchema '/component/', componentSchema

  describe 'output', ->
    describe 'error', ->
      schema = '/component/output/error'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'component'
          command: 'error'
          payload:
            message: "component failed to compile, line fofof:33"

        res = tv4.validateMultiple event, schema
        chai.expect(res.missing).to.eql []
        chai.expect(res.errors).to.eql []
        chai.expect(res.valid).to.equal true

    describe 'component', ->
      schema = '/component/output/component'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'component'
          command: 'component'
          payload:
            name: 'mycomponent'
            subgraph: false
            inPorts: []
            outPorts: []

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

    describe 'source', ->
      schema = '/component/output/source'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'component'
          command: 'source'
          payload:
            name: 'component1'
            language: 'coffeescript'
            code: '-> console.log Array.prototype.slice.call arguments'

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

  describe 'input', ->

    describe 'list', ->
      schema = '/component/input/list'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'component'
          command: 'list'
          payload: {}
          requestId: uuid()

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

    describe 'getsource', ->
      schema = '/component/input/getsource'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'component'
          command: 'getsource'
          payload:
            name: 'component1'
          requestId: uuid()

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

    describe 'source', ->
      schema = '/component/input/source'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'component'
          command: 'source'
          payload:
            name: 'component1'
            language: 'coffeescript'
            code: '-> console.log Array.prototype.slice.call arguments'
          requestId: uuid()

        res = tv4.validate event, schema
        chai.expect(res).to.be.true
