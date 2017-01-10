chai = require 'chai'
schemas = require '../../schema/schemas.js'
tv4 = require 'tv4'
format = require '../../schema/format'

describe 'Test network protocol schema on events', ->
  before ->
    sharedSchema = schemas.shared
    networkSchema = schemas.network
    tv4.addSchema '/shared/', sharedSchema
    tv4.addSchema '/network/', networkSchema
    format(tv4)

  describe 'output', ->
    describe 'stopped', ->
      schema = '/network/output/stopped'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'network'
          command: 'stopped'
          payload:
            time: '2016-05-29T13:26:01.000Z'
            uptime: 1000
            graph: 'mygraph'

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).to.eql []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal true

      it 'should invalidate event with invalid date', ->
        event =
          protocol: 'network'
          command: 'stopped'
          payload:
            time: '5a.m.'
            uptime: 1000
            graph: 'mygraph'

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).to.not.equal []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal false

      it 'should invalidate event with extra fields', ->
        # Tests that /shared/message $ref is added properly
        event =
          hello: true
          protocol: 'network'
          command: 'stopped'
          payload:
            time: '2016-05-29T13:26:01.000Z'
            uptime: 1000
            graph: 'mygraph'

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).to.not.equal []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal false

    describe 'started', ->
      schema = '/network/output/started'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'network'
          command: 'started'
          payload:
            time: '2016-05-29T13:26:01.000Z'
            graph: 'mygraph'

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).to.eql []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal true

    describe 'status', ->
      schema = '/network/output/status'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'network'
          command: 'status'
          payload:
            running: true
            uptime: 1000
            graph: 'mygraph'

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).to.eql []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal true

    describe 'output', ->
      schema = '/network/output/output'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'network'
          command: 'output'
          payload:
            message: 'hello'
            type: 'message'

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).to.eql []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal true

      it 'should invalidate event with invalid type', ->
        event =
          protocol: 'network'
          command: 'output'
          payload:
            message: 'hello'
            type: 'hello'

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).to.not.eql []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal false

    describe 'error', ->
      schema = '/network/output/error'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'network'
          command: 'error'
          payload:
            message: 'oops'

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).to.eql []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal true

    describe 'processerror', ->
      schema = '/network/output/processerror'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'network'
          command: 'processerror'
          payload:
            id: 'node1'
            error: 'BigError'
            graph: 'mygraph'

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).to.eql []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal true

    describe 'icon', ->
      schema = '/network/output/icon'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'network'
          command: 'icon'
          payload:
            id: 'node1'
            icon: 'amazingicon'
            graph: 'mygraph'

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).to.eql []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal true

    describe 'connect', ->
      schema = '/network/output/connect'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'network'
          command: 'connect'
          payload:
            id: 'node1 OUT -> IN node2'
            src:
              node: 'node1'
              port: 'out'
            tgt:
              node: 'node2'
              port: 'in'
            graph: 'mygraph'

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).to.eql []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal true

    describe 'begingroup', ->
      schema = '/network/output/begingroup'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'network'
          command: 'begingroup'
          payload:
            id: 'node1 OUT -> IN node2'
            src:
              node: 'node1'
              port: 'out'
            tgt:
              node: 'node2'
              port: 'in'
            group: 'group1'
            graph: 'mygraph'

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).to.eql []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal true

      it 'should invalidate event without required fields', ->
        event =
          protocol: 'network'
          command: 'begingroup'
          payload:
            id: 'node1 OUT -> IN node2'
            src:
              node: 'node1'
              port: 'out'
            tgt:
              node: 'node2'
              port: 'in'
            graph: 'mygraph'

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).not.to.eql []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal false

      it 'should invalidate event with extra fields', ->
        event =
          protocol: 'network'
          command: 'begingroup'
          payload:
            id: 'node1 OUT -> IN node2'
            src:
              node: 'node1'
              port: 'out'
            tgt:
              node: 'node2'
              port: 'in'
            group: 'group1'
            graph: 'mygraph'
            extra: 'test'

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).not.to.eql []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal false

    describe 'data', ->
      schema = '/network/output/data'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'network'
          command: 'data'
          payload:
            id: 'node1 OUT -> IN node2'
            src:
              node: 'node1'
              port: 'out'
            tgt:
              node: 'node2'
              port: 'in'
            data: 5
            graph: 'mygraph'

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).to.eql []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal true

    describe 'endgroup', ->
      schema = '/network/output/endgroup'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'network'
          command: 'endgroup'
          payload:
            id: 'node1 OUT -> IN node2'
            src:
              node: 'node1'
              port: 'out'
            tgt:
              node: 'node2'
              port: 'in'
            group: 'group1'
            graph: 'mygraph'

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).to.eql []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal true

    describe 'disconnect', ->
      schema = '/network/output/disconnect'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'network'
          command: 'disconnect'
          payload:
            id: 'node1 OUT -> IN node2'
            src:
              node: 'node1'
              port: 'out'
            tgt:
              node: 'node2'
              port: 'in'
            graph: 'mygraph'

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).to.eql []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal true

  describe 'input', ->
    describe 'error', ->
      schema = '/network/input/error'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'network'
          command: 'error'
          payload: {}

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).to.eql []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal true

    describe 'start', ->
      schema = '/network/input/start'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'network'
          command: 'start'
          payload:
            graph: 'start'

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).to.eql []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal true

    describe 'getstatus', ->
      schema = '/network/input/getstatus'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'network'
          command: 'getstatus'
          payload:
            graph: 'mygraph'

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).to.eql []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal true

    describe 'getstatus', ->
      schema = '/network/input/getstatus'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'network'
          command: 'getstatus'
          payload:
            graph: 'mygraph'

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).to.eql []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal true

    describe 'stop', ->
      schema = '/network/input/stop'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'network'
          command: 'stop'
          payload:
            graph: 'mygraph'

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).to.eql []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal true

    describe 'persist', ->
      schema = '/network/input/persist'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'network'
          command: 'persist'
          payload: {}

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).to.eql []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal true

    describe 'debug', ->
      schema = '/network/input/debug'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'network'
          command: 'debug'
          payload:
            enable: true
            graph: 'mygraph'

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).to.eql []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal true

    describe 'edges', ->
      schema = '/network/input/edges'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'network'
          command: 'edges'
          payload:
            edges: [
              src:
                node: 'node1'
                port: 'OUT'
              tgt:
                node: 'node2'
                port: 'IN'
                index: 0
            ]

        res = tv4.validateMultiple event, schema
        chai.expect(res.errors).to.eql []
        chai.expect(res.missing).to.eql []
        chai.expect(res.valid).to.equal true

