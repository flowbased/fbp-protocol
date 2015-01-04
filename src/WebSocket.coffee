chai = require 'chai'
path = require 'path'
# spawn = require('child_process').spawn
shelljs = require 'shelljs'
WebSocketClient = require('websocket').client

check = (done, f) ->
  try
    f()
  catch e
    done e

exports.testRuntime = (runtimeType, startServer, stopServer, host='localhost', port=8080, collection='core') ->
  address = "ws://#{host}:#{port}/"
  describe "#{runtimeType} webSocket network runtime", ->
    client = null
    connection = null
    send = null
    before (done) ->
      tries = 5
      startServer ->
        client = new WebSocketClient
        client.on 'connect', (conn) ->
          connection = conn
          done()
        client.on 'connectFailed', (err) ->
          tries--
          if tries == 0
            console.log "failed to connect to runtime after 5 tries"
            done(err)
          setTimeout(
            ->
              client.connect address, 'noflo'
            100
          )
        console.log "connecting to", address
        client.connect address, 'noflo'
    after stopServer

    send = (protocol, command, payload) ->
      connection.sendUTF JSON.stringify
        protocol: protocol
        command: command
        payload: payload

    receive = (expects, done) ->
      listener = (message) ->
        check done, ->
          chai.expect(message.utf8Data).to.be.a 'string'
          msg = JSON.parse message.utf8Data
          expected = expects.shift()
          if expected.payload
            for key, value of expected.payload
              if value is String
                chai.expect(msg.payload).to.exist
                chai.expect(msg.payload[key]).to.be.a 'string'
                delete expected.payload[key]
                delete msg.payload[key]
              if value is Number
                chai.expect(msg.payload).to.exist
                chai.expect(msg.payload[key]).to.be.a 'number'
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
            check done, ->
              msg = JSON.parse message.utf8Data
              chai.expect(msg.protocol).to.equal 'runtime'
              chai.expect(msg.command).to.equal 'runtime'
              chai.expect(msg.payload).to.be.an 'object'
              chai.expect(msg.payload.type).to.equal runtimeType
              chai.expect(msg.payload.capabilities).to.be.an 'array'
              done()
          send 'runtime', 'getruntime', ''

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
                id: 'Foo'
                component: "#{collection}/Repeat"
                metadata:
                  hello: 'World'
                graph: 'foo'
            ,
              protocol: 'graph'
              command: 'addnode'
              payload:
                id: 'Bar'
                component: "#{collection}/Drop"
                metadata: {}
                graph: 'foo'
          ]
          receive expects, done
          send 'graph', 'clear',
            baseDir: path.resolve __dirname, '../'
            id: 'foo'
            main: true
          send 'graph', 'addnode', expects[1].payload
          send 'graph', 'addnode', expects[2].payload
      describe 'adding an edge', ->
        it 'should provide the edge back', (done) ->
          expects = [
            protocol: 'graph'
            command: 'addedge'
            payload:
              src:
                node: 'Foo'
                port: 'out'
              tgt:
                node: 'Bar'
                port: 'in'
              metadata:
                route: 5
              graph: 'foo'
          ]
          receive expects, done
          send 'graph', 'addedge', expects[0].payload
      describe 'adding metadata', ->
        describe 'to a node with no metadata', ->
          it 'should add the metadata', (done) ->
            expects = [
              protocol: 'graph'
              command: 'changenode'
              payload:
                id: 'Bar'
                metadata:
                  sort: 1
                graph: 'foo'
            ]
            receive expects, done
            send 'graph', 'changenode', expects[0].payload
        describe 'to a node with existing metadata', ->
          it 'should merge the metadata', (done) ->
            expects = [
              protocol: 'graph'
              command: 'changenode'
              payload:
                id: 'Bar'
                metadata:
                  sort: 1
                  tag: 'awesome'
                graph: 'foo'
            ]
            receive expects, done
            send 'graph', 'changenode',
              id: 'Bar'
              metadata:
                tag: 'awesome'
              graph: 'foo'
        describe 'with no keys to a node with existing metadata', ->
          it 'should not change the metadata', (done) ->
            expects = [
              protocol: 'graph'
              command: 'changenode'
              payload:
                id: 'Bar'
                metadata:
                  sort: 1
                  tag: 'awesome'
                graph: 'foo'
            ]
            receive expects, done
            send 'graph', 'changenode',
              id: 'Bar'
              metadata: {}
              graph: 'foo'
        describe 'will a null value removes it from the node', ->
          it 'should merge the metadata', (done) ->
            expects = [
              protocol: 'graph'
              command: 'changenode'
              payload:
                id: 'Bar'
                metadata: {}
                graph: 'foo'
            ]
            receive expects, done
            send 'graph', 'changenode',
              id: 'Bar'
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
                node: 'Foo'
                port: 'in'
              metadata: {}
              graph: 'foo'
          ]
          receive expects, done
          send 'graph', 'addinitial', expects[0].payload
      describe 'removing a node', ->
        it 'should remove the node and its associated edges', (done) ->
          expects = [
            protocol: 'graph'
            command: 'changeedge'
            payload:
              src:
                node: 'Foo'
                port: 'out'
              tgt:
                node: 'Bar'
                port: 'in'
              metadata:
                route: 5
              graph: 'foo'
          ,
            protocol: 'graph'
            command: 'removeedge'
            payload:
              src:
                node: 'Foo'
                port: 'out'
              tgt:
                node: 'Bar'
                port: 'in'
              metadata:
                route: 5
              graph: 'foo'
          ,
            protocol: 'graph'
            command: 'changenode'
            payload:
              id: 'Bar'
              metadata: {}
              graph: 'foo'
          ,
            protocol: 'graph'
            command: 'removenode'
            payload:
              id: 'Bar'
              component: "#{collection}/Drop"
              metadata: {}
              graph: 'foo'
          ]
          receive expects, done
          send 'graph', 'removenode',
            id: 'Bar'
            graph: 'foo'
      describe 'removing an IIP', ->
        it 'should provide the IIP back', (done) ->
          expects = [
            protocol: 'graph'
            command: 'removeinitial'
            payload:
              src:
                data: 'Hello, world!'
              tgt:
                node: 'Foo'
                port: 'in'
              metadata: {}
              graph: 'foo'
          ]
          receive expects, done
          send 'graph', 'removeinitial',
            tgt:
              node: 'Foo'
              port: 'in'
            graph: 'foo'
      describe 'renaming a node', ->
        it 'should send the renamenode event', (done) ->
          expects = [
            protocol: 'graph'
            command: 'renamenode'
            payload:
              from: 'Foo'
              to: 'Baz'
              graph: 'foo'
          ]
          receive expects, done
          send 'graph', 'renamenode', expects[0].payload
      describe 'adding a node to a non-existent graph', ->
        it 'should send an error', (done) ->
          expects = [
            protocol: 'graph',
            command: 'error',
            payload:
              message: 'Requested graph not found'
          ]
          receive expects, done
          send 'graph', 'addnode',
            id: 'Foo'
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
          receive expects, done
          send 'graph', 'addnode',
            id: 'Foo'
            component: "#{collection}/Repeat"
      # TODO:
      # ports:
      #   addinport / removeinport / renameinport
      #   addoutport / removeoutport / renameoutport
      # groups:
      #   addgroup / removegroup / renamegroup / changegroup

    describe 'Network protocol', ->
      # Set up a clean graph
      beforeEach (done) ->
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
          receive expects, done
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
          receive expects, done
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
          receive expects, done
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
          receive expects, done
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
            check done, ->
              chai.expect(message.utf8Data).to.be.a 'string'
              msg = JSON.parse message.utf8Data
              chai.expect(msg.protocol).to.equal 'component'
              chai.expect(msg.payload).to.be.an 'object'
              unless msg.payload.name is "#{collection}/Output"
                connection.once 'message', listener
              else
                expectedInPorts = [
                  id: 'in'
                  type: 'all'
                  required: false
                  addressable: false
                  description: 'Packet to be printed through console.log'
                ,
                  id: 'options'
                  type: 'object'
                  required: false
                  addressable: false
                  description: 'Options to be passed to console.log'
                ]
                # order matters
                chai.expect(msg.payload.inPorts).to.eql expectedInPorts
                chai.expect(msg.payload.outPorts).to.eql [
                  id: 'out'
                  type: 'all'
                  required: false
                  addressable: false
                ]
                done()
          connection.once 'message', listener
          send 'component', 'list', process.cwd()

      # TODO:
      # getsource => source

exports.testRuntimeCommand = (runtimeType, command, host='localhost', port=8080, collection='core') ->
  child = null
  exports.testRuntime( runtimeType,
    (connectClient) ->
      child = shelljs.exec command, {async: true}
      connectClient()
    ->
      child.kill "SIGKILL"
    host
    port
    collection
  )
