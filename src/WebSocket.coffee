chai = require 'chai'
path = require 'path'
# spawn = require('child_process').spawn
shelljs = require 'shelljs'
WebSocketClient = require('websocket').client
semver = require 'semver'
tv4 = require '../schema/index.js'

check = (done, f) ->
  try
    f()
  catch e
    done e

exports.testRuntime = (runtimeType, startServer, stopServer, host='localhost', port=8080, collection='core', version='0.5') ->
  if version.length is 3
    semanticVersion = "#{version}.0"
  else
    semanticVersion = version

  address = "ws://#{host}:#{port}/"
  describe "#{runtimeType} webSocket network runtime version #{version}", ->
    client = null
    connection = null
    send = null
    describe "Connecting to the runtime at #{address}", ->
      it 'should succeed', (done) ->
        @timeout 4000
        tries = 10
        startServer ->
          client = new WebSocketClient
          client.on 'connect', (conn) ->
            connection = conn
            connection.setMaxListeners(1000)
            done()
          client.on 'connectFailed', (err) ->
            tries--
            chai.expect(tries).to.be.above 0
            setTimeout(
              ->
                client.connect address, 'noflo'
              200
            )
          client.connect address, 'noflo'
    after stopServer

    send = (protocol, command, payload) ->
      payload = {} unless payload
      payload.secret = process.env.FBP_PROTOCOL_SECRET if process.env.FBP_PROTOCOL_SECRET
      connection.sendUTF JSON.stringify
        protocol: protocol
        command: command
        payload: payload

    receive = (expects, done, ignore=null) ->
      listener = (message) ->
        check done, ->
          chai.expect(message.utf8Data).to.be.a 'string'
          msg = JSON.parse message.utf8Data

          if not ignore or not ignore(msg)
            expected = expects.shift()
            chai.expect(msg.protocol, 'protocol').to.equal expected.protocol
            chai.expect(msg.command, 'command').to.equal expected.command
            if expected.payload
              for key, value of expected.payload
                type = null
                if value is String
                  type = 'string'
                else if value is Number
                  type = 'number'
                else if value is Array
                  type = 'array'
                if type
                  chai.expect(msg.payload, "payload.#{key}").to.exist
                  chai.expect(msg.payload[key], "payload.#{key}").to.be.a type
                  delete expected.payload[key]
                  delete msg.payload[key]

            chai.expect(msg).to.eql expected
          if expects.length
            connection.once 'message', listener
          else
            done()
      connection.once 'message', listener

    describe 'Runtime Protocol', ->
      describe 'requesting runtime metadata', ->
        it 'should provide it back', (done) ->
          connection.once 'message', (message) ->
            data = message.utf8Data
            chai.expect(tv4.validate data, '/runtime/output/runtime').to.be.true
            done()

          send 'runtime', 'getruntime', {}

    describe 'Graph Protocol', ->
      describe 'adding a graph and nodes', ->
        it 'should provide the nodes back', (done) ->
          expects = [
              protocol: 'graph'
              command: 'clear',
              payload: 
                baseDir: path.resolve __dirname, '../'
                id: 'foo'
                main: true
                name: 'NoFlo runtime'
            ,
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
          #receive expects, done
          connection.once 'message', (message) ->
            data = JSON.parse message.utf8Data
            chai.expect(tv4.validate data, '/graph/output/clear').to.be.true

            connection.once 'message', (message) ->
              data = JSON.parse message.utf8Data

              chai.expect(tv4.validate data, '/graph/output/addnode').to.be.true
              chai.expect(data.payload.id).to.equal expects[1].payload.id

              connection.once 'message', (message) ->
                data = JSON.parse message.utf8Data

                chai.expect(tv4.validate data, '/graph/output/addnode').to.be.true
                chai.expect(data.payload.id).to.equal expects[2].payload.id

                done()

              send 'graph', 'addnode', expects[2].payload

            send 'graph', 'addnode', expects[1].payload

          send 'graph', 'clear',
            baseDir: path.resolve __dirname, '../'
            id: 'foo'
            main: true

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
          connection.once 'message', (message) ->
            data = JSON.parse message.utf8Data

            chai.expect(tv4.validate data, '/graph/output/addedge').to.be.true
            chai.expect(data.payload.src).to.eql expects[0].payload.src
            chai.expect(data.payload.tgt).to.eql expects[0].payload.tgt

            done()

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
            connection.once 'message', (message) ->
              data = JSON.parse message.utf8Data
              chai.expect(tv4.validate data, '/graph/output/changenode').to.be.true
              chai.expect(data.payload.metadata).to.eql expects[0].payload.metadata

              done()

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
            connection.once 'message', (message) ->
              data = JSON.parse message.utf8Data
              chai.expect(tv4.validate data, '/graph/output/changenode').to.be.true
              chai.expect(data.payload.metadata).to.eql expects[0].payload.metadata

              done()

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
            connection.once 'message', (message) ->
              data = JSON.parse message.utf8Data
              chai.expect(tv4.validate data, '/graph/output/changenode').to.be.true
              chai.expect(data.payload.metadata).to.eql expects[0].payload.metadata

              done()

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
            connection.once 'message', (message) ->
              data = JSON.parse message.utf8Data
              chai.expect(tv4.validate data, '/graph/output/changenode').to.be.true
              chai.expect(data.payload.metadata).to.eql expects[0].payload.metadata

              done()

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
          connection.once 'message', (message) ->
            data = JSON.parse message.utf8Data
            chai.expect(tv4.validate data, '/graph/output/addinitial').to.be.true
            chai.expect(data.payload).to.eql expects[0].payload

            done()

          send 'graph', 'addinitial', expects[0].payload

      describe 'removing a node', ->
        it 'should remove the node and its associated edges', (done) ->
          expects = [
            protocol: 'graph'
            command: 'changeedge'
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
          ,
            protocol: 'graph'
            command: 'removeedge'
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
          ,
            protocol: 'graph'
            command: 'changenode'
            payload:
              id: 'Drop1'
              metadata: {}
              graph: 'foo'
          ,
            protocol: 'graph'
            command: 'removenode'
            payload:
              id: 'Drop1'
              component: "#{collection}/Drop"
              metadata: {}
              graph: 'foo'
          ]
          connection.once 'message', (message) ->
            data = JSON.parse message.utf8Data
            chai.expect(tv4.validate data, '/graph/output/removenode').to.be.true
            chai.expect(data.payload).to.eql expects[0].payload

            done()

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
              metadata: {}
              graph: 'foo'
          ]
          connection.once 'message', (message) ->
            data = JSON.parse message.utf8Data
            chai.expect(tv4.validate data, '/graph/output/removeinitial').to.be.true
            chai.expect(data.payload.src).to.eql expects[0].payload.src

            done()

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
          connection.once 'message', (message) ->
            data = JSON.parse message.utf8Data
            chai.expect(tv4.validate data, '/graph/output/renamenode').to.be.true
            chai.expect(data.payload).to.eql expects[0].payload

            done()

          send 'graph', 'renamenode', expects[0].payload

      describe 'adding a node to a non-existent graph', ->
        it 'should send an error', (done) ->
          expects = [
            protocol: 'graph',
            command: 'error',
            payload:
              message: 'Requested graph not found'
              stack: String
          ]
          connection.once 'message', (message) ->
            data = JSON.parse message.utf8Data
            chai.expect(tv4.validate data, '/graph/output/error').to.be.true

            done()

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
              stack: String
          ]
          connection.once 'message', (message) ->
            data = JSON.parse message.utf8Data
            chai.expect(tv4.validate data, '/graph/output/error').to.be.true

            done()

          send 'graph', 'addnode',
            id: 'Repeat1'
            component: "#{collection}/Repeat"

      describe 'adding an in-port to a graph', ->
        it "should ACK", (done) ->
          expects = [
            protocol: 'graph',
            command: 'addinport',
            payload:
              graph: 'foo'
              node: 'RepeatRenamed'
              public: 'in'
              port: 'in'
          ]
          connection.once 'message', (message) ->
            data = JSON.parse message.utf8Data
            chai.expect(tv4.validate data, '/graph/output/addinport').to.be.true
            chai.expect(data.payload).to.equal expects[0].payload

            done()

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
          connection.once 'message', (message) ->
            data = JSON.parse message.utf8Data
            chai.expect(tv4.validate data, '/graph/output/addoutport').to.be.true
            chai.expect(data.payload).to.equal expects[0].payload

            done()

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
          connection.once 'message', (message) ->
            data = JSON.parse message.utf8Data
            chai.expect(tv4.validate data, '/graph/output/removeoutport').to.be.true
            chai.expect(data.payload).to.equal expects[0].payload

            done()

          send 'graph', 'removeoutport',
            public: 'out'
            graph: 'foo'
      # TODO:
      # ports:
      #   removeinport
      #   renameoutport
      # groups:
      #   addgroup / removegroup / renamegroup / changegroup

    describe 'Network protocol', ->
      # Set up a clean graph
      before (done) ->
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
      # getstatus does not return a status when the network has not been started: seems like a bug
      # describe "on requesting a graph's status", ->
      #   it 'should provide the status', (done) ->
      #     expects = [
      #       protocol: 'network'
      #       command: 'status'
      #       payload:
      #         graph: 'bar'
      #         running: false
      #         started: false
      #     ]
      #     receive expects, done
      #     send 'network', 'getstatus',
      #       graph: 'bar'
      describe 'on starting the network', ->
        it 'should process the nodes and stop when it completes', (done) ->
          # send 'network', 'debug',
          #   graph: 'bar'
          #   enable: true
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
            command: 'connect'
            payload: 
               id: 'DATA -> IN Hello()'
               graph: 'bar'
               tgt: { node: 'Hello', port: 'in' }
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
            command: 'connect'
            payload: 
               id: 'Hello() OUT -> IN World()'
               graph: 'bar'
               src: { node: 'Hello', port: 'out' }
               tgt: { node: 'World', port: 'in' }
          ,
            protocol: 'network'
            command: 'data'
            payload: 
               id: 'Hello() OUT -> IN World()'
               graph: 'bar'
               src: { node: 'Hello', port: 'out' }
               tgt: { node: 'World', port: 'in' }
               data: 'Hello, world!'
          ,
            protocol: 'network'
            command: 'disconnect'
            payload: 
               id: 'DATA -> IN Hello()'
               graph: 'bar'
               tgt: { node: 'Hello', port: 'in' }
          ,
            protocol: 'network'
            command: 'disconnect'
            payload: 
               id: 'Hello() OUT -> IN World()'
               graph: 'bar'
               src: { node: 'Hello', port: 'out' }
               tgt: { node: 'World', port: 'in' }
          ]

          connection.once 'message', (message) ->
            data = JSON.parse message.utf8Data
            chai.expect(tv4.validate data, '/network/output/started').to.be.true

            done()

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
          connection.once 'message', (message) ->
            data = JSON.parse message.utf8Data
            chai.expect(tv4.validate data, '/network/output/status').to.be.true
            chai.expect(data.payload.started).to.be.true

            done()

          send 'network', 'getstatus',
            graph: 'bar'
      describe 'on stopping the network', ->
        it 'should be stopped', (done) ->
          expects = [
            protocol: 'network'
            command: 'stopped'
            payload:
              graph: 'bar'
              started: false
              running: false
              time: String
              uptime: Number
          ]
          connection.once 'message', (message) ->
            data = JSON.parse message.utf8Data
            chai.expect(tv4.validate data, '/network/output/stopped').to.be.true

            done()

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
          connection.once 'message', (message) ->
            data = JSON.parse message.utf8Data
            chai.expect(tv4.validate data, '/network/output/stopped').to.be.true
            chai.expect(data.payload.started).to.be.false
            chai.expect(data.payload.running).to.be.false

            done()

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

    describe 'Component protocol', ->
      describe 'on requesting a component list', ->
        it 'should receive some known components', (done) ->
          listener = (message) ->
            data = JSON.parse message.utf8Data
            chai.expect(tv4.validate data, '/component/output/list').to.be.true

            if data.payload.name is "#{collection}/Repeat"
              done()
            else
              connection.once 'message', listener


          connection.once 'message', listener

          send 'component', 'list', collection

      # TODO:
      # getsource => source

exports.testRuntimeCommand = (runtimeType, command=null, host='localhost', port=8080, collection='core', version='0.5') ->
  child = null
  exports.testRuntime( runtimeType,
    (done) ->
      if command
        console.log "running '#{command}'"
        child = shelljs.exec command, {async: true}
      else
        console.log "not running a command. runtime is assumed to be started"
      done()
    ->
      if child
        child.kill "SIGKILL"
    host
    port
    collection
    version
  )
