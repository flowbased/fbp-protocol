chai = require 'chai'
path = require 'path'
{ spawn } = require 'child_process'
WebSocketClient = require('websocket').client
semver = require 'semver'
tv4 = require '../schema/index.js'

validateSchema = (payload, schema) ->
  res = tv4.validateMultiple payload, schema
  chai.expect(res.errors, "#{schema} should produce no errors").to.eql []
  chai.expect(res.valid, "#{schema} should validate").to.equal true
  return res.valid

exports.testRuntime = (runtimeType, startServer, stopServer, host='localhost', port=8080, collection='core', version='0.7') ->
  if version.length is 3
    semanticVersion = "#{version}.0"
  else
    semanticVersion = version

  address = "ws://#{host}:#{port}/"
  describe "#{runtimeType} webSocket network runtime version #{version}", ->
    client = null
    connection = null
    capabilities = []
    send = null
    describe "Connecting to the runtime at #{address}", ->
      it 'should succeed', (done) ->
        @timeout 4000
        tries = 10
        startServer (err) ->
          return done err if err
          client = new WebSocketClient
          onConnected = (conn) ->
            connection = conn
            connection.setMaxListeners(1000)
            client.removeListener 'connectFailed', onFailed
            done()
          onFailed = (err) ->
            tries--
            unless tries
              client.removeListener 'connect', onConnected
              client.removeListener 'connectFailed', onFailed
              done err
              return
            setTimeout ->
              client.connect address, 'noflo'
            , 100
          client.once 'connect', onConnected
          client.on 'connectFailed', onFailed
          client.connect address, 'noflo'
    after (done) ->
      unless connection
        stopServer done
        return
      connection.once 'close', ->
        connection = null
        stopServer done
      connection.drop()

    send = (protocol, command, payload) ->
      payload = {} unless payload
      # FIXME: Remove from payload once runtimes are on 0.8
      payload.secret = process.env.FBP_PROTOCOL_SECRET
      connection.sendUTF JSON.stringify
        protocol: protocol
        command: command
        payload: payload
        secret: process.env.FBP_PROTOCOL_SECRET

    messageMatches = (msg, expected) ->
      return false unless msg.protocol is expected.protocol
      return false unless msg.command is expected.command
      true
    getPacketSchema = (packet) ->
      return "#{packet.protocol}/output/#{packet.command}"

    receive = (expects, done, allowExtraPackets = false) ->
      listener = (message) ->
        # Basic validation
        chai.expect(message.utf8Data).to.be.a 'string'
        data = JSON.parse message.utf8Data
        chai.expect(data.protocol).to.be.a 'string'
        chai.expect(data.command).to.be.a 'string'

        # FIXME: Remove once runtimes are on 0.8
        delete data.payload.secret

        # Validate all received packets against schema
        validateSchema data, getPacketSchema data
        # Don't ever expect payloads to return a secret
        chai.expect(data.secret, 'Message should not contain secret').to.be.a 'undefined'
        chai.expect(data.payload.secret, 'Payload should not contain secret').to.be.a 'undefined'

        if expects[0].command isnt 'error' and data.command is 'error'
          # We received an unexpected error, bail out
          done new Error data.payload
          return

        if allowExtraPackets and not messageMatches data, expects[0]
          # Ignore messages we don't care about in context of the test
          connection.once 'message', listener
          return

        # Validate actual payload
        expected = expects.shift()
        chai.expect(getPacketSchema(data)).to.equal getPacketSchema expected

        # Clear values that can't be checked with deep equal. We already
        # know they passed schema validation
        if data.protocol is 'network'
          if data.command is 'started'
            delete data.payload.time
            delete expected.payload.time
            delete data.payload.running
            delete expected.payload.running
          if data.command is 'stopped'
            delete data.payload.time
            delete expected.payload.time
            delete data.payload.uptime
            delete expected.payload.uptime
        if data.command is 'error'
          delete data.payload.stack
          delete expected.payload.stack

        # FIXME: Remove once runtimes are on 0.8
        delete expected.payload.secret
        # Don't ever expect payloads to return a secret
        delete expected.secret

        chai.expect(data.payload).to.eql expected.payload
        # Received all expected packets
        return done() unless expects.length
        # Still waiting
        connection.once 'message', listener
        return
      connection.once 'message', listener

    describe 'Runtime Protocol', ->
      before ->
        chai.expect(connection, 'Connection needs to be available').not.be.a 'null'
      describe 'requesting runtime metadata', ->
        it 'should provide it back', (done) ->
          connection.once 'message', (message) ->
            data = JSON.parse message.utf8Data
            validateSchema data, 'runtime/output/runtime'
            capabilities = data.payload.capabilities
            done()

          send 'runtime', 'getruntime', {}

    describe 'Graph Protocol', ->
      before ->
        chai.expect(connection, 'Connection needs to be available').not.be.a 'null'
        chai.expect(capabilities, 'Graph protocol should be allowed for user').to.contain 'protocol:graph'
      describe 'adding a graph and nodes', ->
        it 'should provide the nodes back', (done) ->
          expects1 = [
              protocol: 'graph'
              command: 'clear',
              payload:
                id: 'foo'
                main: true
                name: 'Foo graph'
          ]
          expects2 = [
              protocol: 'graph'
              command: 'addnode'
              payload:
                id: 'Repeat1'
                component: "#{collection}/Repeat"
                metadata:
                  hello: 'World'
                graph: 'foo'
            ,
              protocol: 'graph'
              command: 'addnode'
              payload:
                id: 'Drop1'
                component: "#{collection}/Drop"
                metadata: {}
                graph: 'foo'
          ]
          receive expects1, (err) ->
            return done err if err
            receive expects2, done, true
            send 'graph', 'addnode', expects2[0].payload
            send 'graph', 'addnode', expects2[1].payload
          , true
          send 'graph', 'clear',
            baseDir: path.resolve __dirname, '../'
            id: 'foo'
            main: true
            name: 'Foo graph'

      describe 'adding an edge', ->
        it 'should provide the edge back', (done) ->
          expects = [
            protocol: 'graph'
            command: 'addedge'
            payload:
              src:
                node: 'Repeat1'
                port: 'out'
              tgt:
                node: 'Drop1'
                port: 'in'
              metadata:
                route: 5
              graph: 'foo'
          ]
          receive expects, done, true
          send 'graph', 'addedge', expects[0].payload
      # describe 'adding an edge to a non-existent node', ->
      #   it 'should return an error', (done) ->
      #     expects = [
      #       protocol: 'graph'
      #       command: 'error'
      #       payload:
      #         msg: 'Requested port not found'
      #     ]
      #     receive expects, done
      #     send 'graph', 'addedge',
      #       protocol: 'graph'
      #       command: 'addedge'
      #       payload:
      #         src:
      #           node: 'non-existent'
      #           port: 'out'
      #         tgt:
      #           node: 'Drop1'
      #           port: 'in'
      #         graph: 'foo'
      # describe 'adding an edge to a non-existent port', ->
      #   it 'should return an error', (done) ->
      #     expects = [
      #       protocol: 'graph'
      #       command: 'error'
      #       payload:
      #         msg: 'Requested port not found'
      #     ]
      #     receive expects, done
      #     send 'graph', 'addedge',
      #       protocol: 'graph'
      #       command: 'addedge'
      #       payload:
      #         src:
      #           node: 'Repeat1'
      #           port: 'non-existent'
      #         tgt:
      #           node: 'Drop1'
      #           port: 'in'
      #         graph: 'foo'
      describe 'adding metadata', ->
        describe 'to a node with no metadata', ->
          it 'should add the metadata', (done) ->
            expects = [
              protocol: 'graph'
              command: 'changenode'
              payload:
                id: 'Drop1'
                metadata:
                  sort: 1
                graph: 'foo'
            ]
            receive expects, done, true
            send 'graph', 'changenode', expects[0].payload

        describe 'to a node with existing metadata', ->
          it 'should merge the metadata', (done) ->
            expects = [
              protocol: 'graph'
              command: 'changenode'
              payload:
                id: 'Drop1'
                metadata:
                  sort: 1
                  tag: 'awesome'
                graph: 'foo'
            ]
            receive expects, done, true
            send 'graph', 'changenode',
              id: 'Drop1'
              metadata:
                tag: 'awesome'
              graph: 'foo'

        describe 'with no keys to a node with existing metadata', ->
          it 'should not change the metadata', (done) ->
            expects = [
              protocol: 'graph'
              command: 'changenode'
              payload:
                id: 'Drop1'
                metadata:
                  sort: 1
                  tag: 'awesome'
                graph: 'foo'
            ]
            receive expects, done, true
            send 'graph', 'changenode',
              id: 'Drop1'
              metadata: {}
              graph: 'foo'

        describe 'with a null value removes it from the node', ->
          it 'should merge the metadata', (done) ->
            expects = [
              protocol: 'graph'
              command: 'changenode'
              payload:
                id: 'Drop1'
                metadata: {}
                graph: 'foo'
            ]
            receive expects, done, true
            send 'graph', 'changenode',
              id: 'Drop1'
              metadata:
                sort: null
                tag: null
              graph: 'foo'

      describe 'adding an IIP', ->
        it 'should provide the IIP back', (done) ->
          expects = [
            protocol: 'graph'
            command: 'addinitial'
            payload:
              src:
                data: 'Hello, world!'
              tgt:
                node: 'Repeat1'
                port: 'in'
              metadata: {}
              graph: 'foo'
          ]
          receive expects, done, true
          send 'graph', 'addinitial', expects[0].payload

      describe 'removing a node', ->
        it 'should remove the node and its associated edges', (done) ->
          expects = [
            protocol: 'graph'
            command: 'removeedge'
            payload:
              src:
                node: 'Repeat1'
                port: 'out'
              tgt:
                node: 'Drop1'
                port: 'in'
              graph: 'foo'
          ,
            protocol: 'graph'
            command: 'removenode'
            payload:
              id: 'Drop1'
              graph: 'foo'
          ]
          # Runtimes can send 'changeedge' and 'changenode' as part
          # of the response for better fbp-graph/Journal behavior
          receive expects, done, true
          send 'graph', 'removenode',
            id: 'Drop1'
            graph: 'foo'

      describe 'removing an IIP', ->
        it 'should provide response that iip was removed', (done) ->
          expects = [
            protocol: 'graph'
            command: 'removeinitial'
            payload:
              src:
                data: 'Hello, world!'
              tgt:
                node: 'Repeat1'
                port: 'in'
              graph: 'foo'
          ]
          receive expects, done, true
          send 'graph', 'removeinitial',
            tgt:
              node: 'Repeat1'
              port: 'in'
            graph: 'foo'

      describe 'renaming a node', ->
        it 'should send the renamenode event', (done) ->
          expects = [
            protocol: 'graph'
            command: 'renamenode'
            payload:
              from: 'Repeat1'
              to: 'RepeatRenamed'
              graph: 'foo'
          ]
          receive expects, done, true
          send 'graph', 'renamenode', expects[0].payload

      describe 'adding a node to a non-existent graph', ->
        it 'should send an error', (done) ->
          expects = [
            protocol: 'graph',
            command: 'error',
            payload:
              message: 'Requested graph not found'
          ]
          receive expects, done, true
          send 'graph', 'addnode',
            id: 'Repeat1'
            component: "#{collection}/Repeat"
            graph: 'another-graph'

      describe 'adding a node without specifying a graph', ->
        it 'should send an error', (done) ->
          expects = [
            protocol: 'graph',
            command: 'error',
            payload:
              message: 'No graph specified'
          ]
          receive expects, done, true
          send 'graph', 'addnode',
            id: 'Repeat1'
            component: "#{collection}/Repeat"

      describe 'adding an in-port to a graph', ->
        it "should ACK", (done) ->
          expects = [
            protocol: 'graph',
            command: 'addinport',
            payload:
              node: 'RepeatRenamed'
              graph: 'foo'
              public: 'in'
              port: 'in'
          ]
          receive expects, done, true
          send 'graph', 'addinport',
            public: 'in'
            node: 'RepeatRenamed'
            port: 'in'
            graph: 'foo'
      # describe 'adding an in-port to a non-existent port', ->
      #   it "should return an error", (done) ->
      #     expects = [
      #       protocol: 'graph',
      #       command: 'error',
      #       payload:
      #         msg: 'Requested port not found'
      #     ]
      #     receive expects, done
      #     send 'graph', 'addinport',
      #       public: 'in'
      #       node: 'non-existent'
      #       port: 'in'
      #       graph: 'foo'
      describe 'adding an out-port to a graph', ->
        it "should ACK", (done) ->
          expects = [
            protocol: 'graph',
            command: 'addoutport',
            payload:
              graph: 'foo'
              node: 'RepeatRenamed'
              port: 'out'
              public: 'out'
          ]
          receive expects, done, true
          send 'graph', 'addoutport',
            public: 'out'
            node: 'RepeatRenamed'
            port: 'out'
            graph: 'foo'
      # describe 'renaming an in-port of a graph', ->
      #   it "should provide the graph's ports back", (done) ->
      #     expects = [
      #       protocol: 'runtime',
      #       command: 'ports',
      #       payload:
      #         graph: 'foo'
      #         inPorts:
      #           [
      #             addressable: false
      #             id: "input"
      #             required: false
      #             type: "any"
      #           ]
      #         outPorts:
      #           [
      #             addressable: false
      #             id: "out"
      #             required: false
      #             type: "any"
      #           ]
      #     ]
      #     receive expects, done
      #     send 'graph', 'renameinport',
      #       from: 'in'
      #       to: 'input'
      #       graph: 'foo'
      describe 'removing an out-port of a graph', ->
        it "should ACK", (done) ->
          expects = [
            protocol: 'graph',
            command: 'removeoutport',
            payload:
              graph: 'foo'
              public: 'out'
          ]
          receive expects, done, true
          send 'graph', 'removeoutport',
            public: 'out'
            graph: 'foo'
      # TODO:
      # ports:
      #   removeinport
      #   renameoutport
      # groups:
      #   addgroup / removegroup / renamegroup / changegroup

    describe 'Network Protocol', ->
      # Set up a clean graph
      before (done) ->
        chai.expect(connection, 'Connection needs to be available').not.be.a 'null'
        chai.expect(capabilities, 'Network protocol should be allowed for user').to.contain 'protocol:network'
        waitFor = 5  # set this to the number of commands below
        listener = (message) ->
          waitFor--
          if waitFor
            connection.once 'message', listener
          else
            done()
        connection.once 'message', listener
        send 'graph', 'clear',
          baseDir: path.resolve __dirname, '../'
          id: 'bar'
          main: true
        send 'graph', 'addnode',
          id: 'Hello'
          component: "#{collection}/Repeat"
          metadata: {}
          graph: 'bar'
        send 'graph', 'addnode',
          id: 'World'
          component: "#{collection}/Drop"
          metadata: {}
          graph: 'bar'
        send 'graph', 'addedge',
          src:
            node: 'Hello'
            port: 'out'
          tgt:
            node: 'World'
            port: 'in'
          graph: 'bar'
        send 'graph', 'addinitial',
          src:
            data: 'Hello, world!'
          tgt:
            node: 'Hello'
            port: 'in'
          graph: 'bar'

      describe 'on starting the network', ->
        it 'should process the nodes and stop when it completes', (done) ->
          expects = [
            protocol: 'network'
            command: 'started'
            payload:
              graph: 'bar'
              started: true
              running: true
              time: String
          ,
            protocol: 'network'
            command: 'data'
            payload:
               id: 'DATA -> IN Hello()'
               graph: 'bar'
               tgt: { node: 'Hello', port: 'in' }
               data: 'Hello, world!'
          ,
            protocol: 'network'
            command: 'data'
            payload:
               id: 'Hello() OUT -> IN World()'
               graph: 'bar'
               src: { node: 'Hello', port: 'out' }
               tgt: { node: 'World', port: 'in' }
               data: 'Hello, world!'
          ]
          receive expects, done, true
          send 'network', 'start',
            graph: 'bar'

        it "should provide a 'started' status", (done) ->
          expects = [
            protocol: 'network'
            command: 'status'
            payload:
              graph: 'bar'
              running: false
              started: true
          ]
          receive expects, done, true
          send 'network', 'getstatus',
            graph: 'bar'
      describe 'on stopping the network', ->
        it 'should be stopped', (done) ->
          expects = [
            protocol: 'network'
            command: 'stopped'
            payload:
              graph: 'bar'
              running: false
              started: false
          ]
          receive expects, done, true
          send 'network', 'stop',
            graph: 'bar'

        it "should provide a 'stopped' status", (done) ->
          expects = [
            protocol: 'network'
            command: 'status'
            payload:
              graph: 'bar'
              running: false
              started: false
          ]
          receive expects, done, true
          send 'network', 'getstatus',
            graph: 'bar'
      # describe 'on console output', ->
      #   it 'should be able to capture and transmit it', (done) ->
      #     listener = (message) ->
      #       check done, ->
      #         rt.stopCapture()
      #         chai.expect(message.utf8Data).to.be.a 'string'
      #         msg = JSON.parse message.utf8Data
      #         chai.expect(msg.protocol).to.equal 'network'
      #         chai.expect(msg.command).to.equal 'output'
      #         chai.expect(msg.payload).to.be.an 'object'
      #         chai.expect(msg.payload.message).to.equal 'Hello, World!'
      #         done()
      #     connection.once 'message', listener
      #     rt.startCapture()
      #     console.log 'Hello, World!'

    describe 'Component Protocol', ->
      before ->
        chai.expect(connection, 'Connection needs to be available').not.be.a 'null'
        chai.expect(capabilities, 'Component protocol should be allowed for connection').to.contain 'protocol:component'
      describe 'on requesting a component list', ->
        it 'should receive some known components', (done) ->
          @timeout 20000
          listener = (message) ->
            data = JSON.parse message.utf8Data
            validateSchema data, '/component/output/list'

            if data.payload.name is "#{collection}/Repeat"
              done()
            else
              connection.once 'message', listener


          connection.once 'message', listener

          send 'component', 'list', {}

      # TODO:
      # getsource => source

exports.testRuntimeCommand = (runtimeType, command=null, host='localhost', port=8080, collection='core', version='0.7') ->
  child = null
  prefix = '      '
  exports.testRuntime( runtimeType,
    (done) ->
      unless command
        console.log "#{prefix}not running a command. runtime is assumed to be started"
        done()
        return
      console.log "#{prefix}\"#{command}\" starting"
      returned = false
      child = spawn command, [],
        cwd: process.cwd()
        shell: true
        stdio: [
          'ignore'
          'pipe'
          'ignore'
        ]
      child.once 'error', (err) ->
        child = null
        return if returned
        returned = true
        done err
      child.stdout.once 'data', (data) ->
        console.log "#{prefix}\"#{command}\" has started"
        setTimeout ->
          return if returned
          returned = true
          done()
        , 100
      child.once 'close', ->
        console.log "#{prefix}\"#{command}\" exited"
        child = null
        return if returned
        returned = true
        done new Error 'Child exited'
    (done) ->
      return done() unless child
      child.once 'close', ->
        done()
      child.stdout.destroy()
      child.kill()
      setTimeout ->
        # If SIGTERM didn't do it, try harder
        return unless child
        child.kill 'SIGKILL'
      , 100
    host
    port
    collection
    version
  )
