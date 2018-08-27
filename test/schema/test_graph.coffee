chai = require 'chai'
schemas = require '../../schema/schemas.js'
tv4 = require 'tv4'
uuid = require 'uuid/v4'

describe 'Test graph protocol schema on event', ->
  before ->
    sharedSchema = schemas.shared
    graphSchema = schemas.graph
    tv4.addSchema '/shared/', sharedSchema
    tv4.addSchema '/graph/', graphSchema

  describe 'addnode', ->
    schema = '/graph/input/addnode'

    it 'should have input schema', ->
      chai.expect(tv4.getSchema schema).to.exist

    it 'should have output shema', ->
      chai.expect(tv4.getSchema(schema).properties).to.eql(
        tv4.getSchema('/graph/output/addnode').properties)

    it 'should validate event with required fields', ->
      event =
        protocol: 'graph'
        command: 'addnode'
        payload:
          id: 'node1'
          component: 'core/Kick'
          graph: 'mygraph'
        requestId: uuid()

      res = tv4.validate event, schema
      chai.expect(res).to.be.true

    it 'should invalidate additional properties', ->
      event =
        protocol: 'graph'
        command: 'addnode'
        payload:
          id: 'node1'
          component: 'core/Kick'
          graph: 'mygraph'
          whatisthis: 'notallowed'
        requestId: uuid()

      res = tv4.validate event, schema
      chai.expect(res).to.be.false

    it 'should invalidate event without required fields', ->
      event =
        protocol: 'graph'
        payload:
          id: 'node1'
          component: 'core/Kick'
          graph: 'mygraph'
        requestId: uuid()


      res = tv4.validate event, schema
      chai.expect(res).to.be.false

      event =
        protocol: 'graph'
        command: 'removenode'
        payload:
          id: 'node1'
          component: 'core/Kick'
          graph: 'mygraph'
        requestId: uuid()

  describe 'removenode', ->
    schema = '/graph/input/removenode'

    it 'should have input schema', ->
      chai.expect(tv4.getSchema schema).to.exist

    it 'should have output shema', ->
      chai.expect(tv4.getSchema(schema).properties).to.eql(
        tv4.getSchema('/graph/output/removenode').properties)

    it 'should validate event with required fields', ->
      event =
        protocol: 'graph'
        command: 'removenode'
        payload:
          id: 'node1'
          graph: 'mygraph'
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.true

  describe 'renamenode', ->
    schema = '/graph/input/renamenode'

    it 'should have input schema', ->
      chai.expect(tv4.getSchema schema).to.exist

    it 'should have output shema', ->
      chai.expect(tv4.getSchema(schema).properties).to.eql(
        tv4.getSchema('/graph/output/renamenode').properties)

    it 'should validate event with required fields', ->
      event =
        protocol: 'graph'
        command: 'renamenode'
        payload:
          from: 'node1'
          to: 'node2'
          graph: 'mygraph'
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.true

  describe 'changenode', ->
    schema = '/graph/input/changenode'

    it 'should have input schema', ->
      chai.expect(tv4.getSchema schema).to.exist

    it 'should have output shema', ->
      chai.expect(tv4.getSchema(schema).properties).to.eql(
        tv4.getSchema('/graph/output/changenode').properties)

    it 'should validate event with required fields', ->
      event =
        protocol: 'graph'
        command: 'changenode'
        payload:
          id: 'node1'
          graph: 'mygraph'
          metadata:
            x: 5
            y: -1000
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.true

    it 'should invalidate event without required fields', ->
      event =
        protocol: 'graph'
        command: 'changenode'
        payload:
          id: 'node1'
          graph: 'mygraph'
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.false

  describe 'addedge', ->
    schema = '/graph/input/addedge'

    it 'should have input schema', ->
      chai.expect(tv4.getSchema schema).to.exist

    it 'should have output schema', ->
      chai.expect(tv4.getSchema(schema).properties).to.eql(
        tv4.getSchema('/graph/output/addedge').properties)

    it 'should validate event with required fields', ->
      event =
        protocol: 'graph'
        command: 'addedge'
        payload:
          graph: 'mygraph'
          src:
            node: 'node1'
            port: 'OUT'
          tgt:
            node: 'node2'
            port: 'IN'
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.true

    it 'should invalidate event without required fields', ->
      event =
        protocol: 'graph'
        command: 'addedge'
        payload:
          graph: 'mygraph'
          src:
            port: 'OUT'
          tgt:
            port: 'IN'
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.false

  describe 'removeedge', ->
    schema = '/graph/input/removeedge'

    it 'should have input schema', ->
      chai.expect(tv4.getSchema schema).to.exist

    it 'should have output schema', ->
      chai.expect(tv4.getSchema(schema).properties).to.eql(
        tv4.getSchema('/graph/output/removeedge').properties)

    it 'should validate event with required fields', ->
      event =
        protocol: 'graph'
        command: 'removeedge'
        payload:
          graph: 'mygraph'
          src:
            node: 'node1'
            port: 'OUT'
          tgt:
            node: 'node2'
            port: 'IN'
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.true

  describe 'changeedge', ->
    schema = '/graph/input/changeedge'

    it 'should have input schema', ->
      chai.expect(tv4.getSchema schema).to.exist

    it 'should have output schema', ->
      chai.expect(tv4.getSchema(schema).properties).to.eql(
        tv4.getSchema('/graph/output/changeedge').properties)

    it 'should validate event with required fields', ->
      event =
        protocol: 'graph'
        command: 'changeedge'
        payload:
          graph: 'mygraph'
          src:
            node: 'node1'
            port: 'OUT'
          tgt:
            node: 'node2'
            port: 'IN'
          metadata:
            route: 1
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.true

  describe 'addinitial', ->
    schema = '/graph/input/addinitial'

    it 'should have input schema', ->
      chai.expect(tv4.getSchema schema).to.exist

    it 'should have output shema', ->
      chai.expect(tv4.getSchema(schema).properties).to.eql(
        tv4.getSchema('/graph/output/addinitial').properties)

    it 'should validate event with required fields', ->
      event =
        protocol: 'graph'
        command: 'addinitial'
        payload:
          graph: 'mygraph'
          src:
            data: 5
          tgt:
            node: 'node2'
            port: 'IN'
        requestId: uuid()

      res = tv4.validateMultiple event, schema
      chai.expect(res.missing).to.eql []
      chai.expect(res.errors).to.eql []
      chai.expect(res.valid).to.be.true

    it 'should invalidate event without required fields', ->
        event =
          protocol: 'graph'
          command: 'addinitial'
          payload:
            graph: 'mygraph'
            src: {}
            tgt:
              port: 'IN'
              node: 'node2'
          requestId: uuid()

        chai.expect(tv4.validate event, schema).to.be.false

  describe 'removeinitial', ->
    schema = '/graph/input/removeinitial'

    it 'should have input shema', ->
      chai.expect(tv4.getSchema schema).to.exist

    it 'should have output shema', ->
      chai.expect(tv4.getSchema(schema).properties).to.eql(
        tv4.getSchema('/graph/output/removeinitial').properties)

    it 'should validate event with required fields', ->
      event =
        protocol: 'graph'
        command: 'removeinitial'
        payload:
          graph: 'mygraph'
          tgt:
            node: 'node2'
            port: 'IN'
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.true

    it 'should invalidate event with extra fields', ->
      event =
        protocol: 'graph'
        command: 'removeinitial'
        payload:
          graph: 'mygraph'
          metadata:
            route: 5
          tgt:
            node: 'node2'
            port: 'IN'
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.false

  describe 'addinport', ->
    schema = '/graph/input/addinport'

    it 'should have input shema', ->
      chai.expect(tv4.getSchema schema).to.exist

    it 'should have output schema', ->
      chai.expect(tv4.getSchema(schema).properties).to.eql(
        tv4.getSchema('/graph/output/addinport').properties)

    it 'should validate event with required fields', ->
      event =
        protocol: 'graph'
        command: 'addinport'
        payload:
          graph: 'mygraph'
          public: 'IN'
          node: 'core/Kick'
          port: 'DATA'
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.true

    it 'should invalidate event with extra fields', ->
      event =
        protocol: 'graph'
        command: 'addinport'
        payload:
          graph: 'mygraph'
          public: 'IN'
          node: 'core/Kick'
          port: 'DATA'
          extra: 'doesntwork'
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.false

  describe 'removeinport', ->
    schema = '/graph/input/removeinport'

    it 'should have input shema', ->
      chai.expect(tv4.getSchema schema).to.exist

    it 'should have output schema', ->
      chai.expect(tv4.getSchema(schema).properties).to.eql(
        tv4.getSchema('/graph/output/removeinport').properties)

    it 'should validate event with required fields', ->
      event =
        protocol: 'graph'
        command: 'removeinport'
        payload:
          graph: 'mygraph'
          public: 'IN'
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.true

    it 'should invalidate event with extra fields', ->
      event =
        protocol: 'graph'
        command: 'removeinport'
        payload:
          graph: 'mygraph'
          public: 'IN'
          node: 'core/Kick'
          port: 'DATA'
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.false

  describe 'renameinport', ->
    schema = '/graph/input/renameinport'

    it 'should have input shema', ->
      chai.expect(tv4.getSchema schema).to.exist

    it 'should have output schema', ->
      chai.expect(tv4.getSchema(schema).properties).to.eql(
        tv4.getSchema('/graph/output/renameinport').properties)

    it 'should validate event with required fields', ->
      event =
        protocol: 'graph'
        command: 'renameinport'
        payload:
          graph: 'mygraph'
          from: 'IN'
          to: 'MORE_IN'
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.true

  describe 'addoutport', ->
    schema = '/graph/input/addoutport'

    it 'should have input shema', ->
      chai.expect(tv4.getSchema schema).to.exist

    it 'should have output schema', ->
      chai.expect(tv4.getSchema(schema).properties).to.eql(
        tv4.getSchema('/graph/output/addoutport').properties)

    it 'should validate event with required fields', ->
      event =
        protocol: 'graph'
        command: 'addoutport'
        payload:
          graph: 'mygraph'
          public: 'OUT'
          node: 'core/Repeat'
          port: 'OUT'
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.true

    it 'should invalidate event with extra fields', ->
      event =
        protocol: 'graph'
        command: 'addoutport'
        payload:
          graph: 'mygraph'
          public: 'OUT'
          node: 'core/Repeat'
          port: 'OUT'
          extra: 'doesntwork'
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.false

  describe 'removeoutport', ->
    schema = '/graph/input/removeoutport'

    it 'should have input shema', ->
      chai.expect(tv4.getSchema schema).to.exist

    it 'should have output schema', ->
      chai.expect(tv4.getSchema(schema).properties).to.eql(
        tv4.getSchema('/graph/output/removeoutport').properties)

    it 'should validate event with required fields', ->
      event =
        protocol: 'graph'
        command: 'removeoutport'
        payload:
          graph: 'mygraph'
          public: 'OUT'
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.true

    it 'should invalidate event with extra fields', ->
      event =
        protocol: 'graph'
        command: 'removeoutport'
        payload:
          graph: 'mygraph'
          public: 'OUT'
          node: 'core/Kick'
          port: 'DATA'
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.false

  describe 'renameoutport', ->
    schema = '/graph/input/renameoutport'

    it 'should have input shema', ->
      chai.expect(tv4.getSchema schema).to.exist

    it 'should have output schema', ->
      chai.expect(tv4.getSchema(schema).properties).to.eql(
        tv4.getSchema('/graph/output/renameoutport').properties)

    it 'should validate event with required fields', ->
      event =
        protocol: 'graph'
        command: 'renameoutport'
        payload:
          graph: 'mygraph'
          from: 'OUT'
          to: 'MORE_OUT'
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.true

  describe 'addgroup', ->
    schema = '/graph/input/addgroup'

    it 'should have input schema', ->
      chai.expect(tv4.getSchema schema).to.exist

    it 'should have output shema', ->
      chai.expect(tv4.getSchema(schema).properties).to.eql(
        tv4.getSchema('/graph/output/addgroup').properties)

    it 'should validate event with required fields', ->
      event =
        protocol: 'graph'
        command: 'addgroup'
        payload:
          graph: 'mygraph'
          name: 'mygroup'
          nodes: ['Kick', 'Drop']
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.true

    it 'should invalidate event with extra fields', ->
      event =
        protocol: 'graph'
        command: 'addgroup'
        payload:
          graph: 'mygraph'
          name: 'mygroup'
          nodes: ['Kick', 'Drop']
          extra: 'nope'
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.false

  describe 'removegroup', ->
    schema = '/graph/input/removegroup'

    it 'should have input shema', ->
      chai.expect(tv4.getSchema schema).to.exist

    it 'should have output schema', ->
      chai.expect(tv4.getSchema(schema).properties).to.eql(
        tv4.getSchema('/graph/output/removegroup').properties)

    it 'should validate event with required fields', ->
      event =
        protocol: 'graph'
        command: 'removegroup'
        payload:
          graph: 'mygraph'
          name: 'mygroup'
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.true

  describe 'renamegroup', ->
    schema = '/graph/input/renamegroup'

    it 'should have input shema', ->
      chai.expect(tv4.getSchema schema).to.exist

    it 'should have output schema', ->
      chai.expect(tv4.getSchema(schema).properties).to.eql(
        tv4.getSchema('/graph/output/renamegroup').properties)

    it 'should validate event with required fields', ->
      event =
        protocol: 'graph'
        command: 'renamegroup'
        payload:
          graph: 'mygraph'
          from: 'mygroup'
          to: 'yourgroup'
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.true

  describe 'changegroup', ->
    schema = '/graph/input/changegroup'

    it 'should have input schema', ->
      chai.expect(tv4.getSchema schema).to.exist

    it 'should have output shema', ->
      chai.expect(tv4.getSchema(schema).properties).to.eql(
        tv4.getSchema('/graph/output/changegroup').properties)

    it 'should validate event with required fields', ->
      event =
        protocol: 'graph'
        command: 'changegroup'
        payload:
          graph: 'mygraph'
          name: 'mygroup'
          metadata: {}
        requestId: uuid()

      chai.expect(tv4.validate event, schema).to.be.true
