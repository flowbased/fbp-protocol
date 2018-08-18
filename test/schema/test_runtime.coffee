chai = require 'chai'
schemas = require '../../schema/schemas.js'
tv4 = require 'tv4'
uuid = require 'uuid/v4'

describe 'Test runtime protocol schema on event', ->
  before ->
    sharedSchema = schemas.shared
    runtimeSchema = schemas.runtime
    tv4.addSchema '/shared/', sharedSchema
    tv4.addSchema '/runtime/', runtimeSchema

  describe 'input', ->

    describe 'getruntime', ->
      schema = '/runtime/input/getruntime'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'runtime'
          command: 'getruntime'
          payload: {}
          requestId: uuid()

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

    describe 'packet', ->
      schema = '/runtime/input/packet'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'runtime'
          command: 'packet'
          payload:
            port: 'IN'
            graph: 'mygraph'
            event: 'connect'
          requestId: uuid()

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

      it 'should invalidate event with invalid enum choice', ->
        event =
          protocol: 'runtime'
          command: 'packet'
          payload:
            port: 'IN'
            graph: 'mygraph'
            event: 'bad event'
          requestId: uuid()

        res = tv4.validate event, schema
        chai.expect(res).to.be.false

  describe 'output', ->
    describe 'error', ->
      schema = '/runtime/output/error'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'runtime'
          command: 'error'
          payload:
            message: 'inport "foo" for runtime:packet does not exist'

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

    describe 'ports', ->
      schema = '/runtime/output/ports'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'runtime'
          command: 'ports'
          payload:
            graph: 'mygraph'
            inPorts: [
              id: 'IN'
              addressable: true
              type: 'string'
            ]
            outPorts: []

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

    describe 'runtime', ->
      schema = '/runtime/output/runtime'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'runtime'
          command: 'runtime'
          payload:
            version: '0.2'
            capabilities: [
              'protocol:network'
              'protocol:runtime'
              'network:persist'
            ]
            type: 'noflo'

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

