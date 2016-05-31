chai = require 'chai'
fs = require 'fs'
tv4 = require 'tv4'
format = require '../../schema/format'

describe 'Test network protocol schema on events', ->
  before ->
    sharedSchema = JSON.parse fs.readFileSync './schema/json/shared.json'
    networkSchema = JSON.parse fs.readFileSync './schema/json/network.json'
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
            time: '2016-05-29 13:26:01Z-1:00'
            uptime: 1000
            graph: 'mygraph'

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

      it 'should invalidate event with invalid date', ->
        event =
          protocol: 'network'
          command: 'stopped'
          payload:
            time: '5:00PM'
            uptime: 1000
            graph: 'mygraph'

        res = tv4.validate event, schema
        chai.expect(res).to.be.false

      it 'should invalidate event with extra fields', ->
        # Tests that /shared/message $ref is added properly
        event =
          hello: true
          protocol: 'network'
          command: 'stopped'
          payload:
            time: '5:00PM'
            uptime: 1000
            graph: 'mygraph'

        res = tv4.validate event, schema
        chai.expect(res).to.be.false

    describe 'started', ->
      schema = '/network/output/started'

      it 'should have schema', ->
        chai.expect(tv4.getSchema schema).to.exist

      it 'should validate event with required fields', ->
        event =
          protocol: 'network'
          command: 'started'
          payload:
            time: '2016-05-29T13:26:01Z+1:00'
            graph: 'mygraph'

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

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

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

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

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

      it 'should invalidate event with invalid type', ->
        event =
          protocol: 'network'
          command: 'output'
          payload:
            message: 'hello'
            type: 'hello'

        res = tv4.validate event, schema
        chai.expect(res).to.be.false

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

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

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

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

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
              process: 'node1'
              port: 'out'
            tgt:
              process: 'node2'
              port: 'in'
            graph: 'mygraph'

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

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
              process: 'node1'
              port: 'out'
            tgt:
              process: 'node2'
              port: 'in'
            group: 'group1'
            graph: 'mygraph'

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

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
              process: 'node1'
              port: 'out'
            tgt:
              process: 'node2'
              port: 'in'
            data: 5
            graph: 'mygraph'

        res = tv4.validate event, schema
        chai.expect(res).to.be.true


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
              process: 'node1'
              port: 'out'
            tgt:
              process: 'node2'
              port: 'in'
            group: 'group1'
            graph: 'mygraph'

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

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
              process: 'node1'
              port: 'out'
            tgt:
              process: 'node2'
              port: 'in'
            graph: 'mygraph'

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

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

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

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

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

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

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

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

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

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

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

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
                process: 'node1'
                port: 'OUT'
              tgt:
                process: 'node2'
                port: 'IN'
                index: 0
            ]

        res = tv4.validate event, schema
        chai.expect(res).to.be.true

