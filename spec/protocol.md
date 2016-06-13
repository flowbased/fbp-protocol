---
title: FBP Network Protocol
layout: documentation
---
The Flow-Based Programming network protocol (*FBP protocol*) has been designed primarily for flow-based programming interfaces like the [NoFlo UI](http://www.kickstarter.com/projects/noflo/noflo-development-environment) to communicate with various FBP runtimes. However, it can also be utilized for communication between different runtimes, for example server-to-server or server-to-microcontroller.

## Implementations

Clients

* [noflo-ui](https://github.com/noflo/noflo-ui) is an open source visual IDE, which powers [Flowhub](http://flowhub.io)
* [fbp-spec](https://github.com/flowbased/fbp-spec) is a data-driven testing tool for FBP components/graphs.
* [fbp-protocol-client](https://github.com/flowbased/fbp-protocol-client) is a JavaScript client library supporting all the common FBP protocol transports

Runtimes

* [noflo-runtime-base](https://github.com/noflo/noflo-runtime-base) is a transport-independent implementation of the protocol for [NoFlo](http://noflojs.org), client-side and server-side JavaScript programming. WebSocket, WebRTC and iFrame implementations exists.
* [microflo](https://github.com/jonnor/microflo) is a WebSocket implementation of the protocol in JS/C++, for microcontrollers and embedded systems
* [Elixir FBP](http://www.elixirfbp.org/) is a WebSocket implementation in Elixir, for programming with systems in Elixir runnin on the Erlang VM.
* [imgflo](https://github.com/jonnor/imgflo) is a WebSocket implementation in C, for image processing
* [javafbp-runtime](https://github.com/jonnor/javafbp-runtime) is a Websocket implementation in Java for [JavaFBP](https://github.com/jpaulm/javafbp), for JRE and Android development
* [sndflo](https://github.com/jonnor/sndflo) is a WebSocket implementation for the SuperCollider audio programming environment
* [MsgFlo](https://github.com/the-grid/msgflo) is a Websocket implementation in Node.js for heterogenous distributed systems communicating via message queues
* [pflow](https://github.com/LumaPictures/pflow) is a Python FBP runtime implementation, with support for the protocol over WebSocket.

Some [examples](https://github.com/flowbased/protocol-examples) have also been created, to help implementors.

## Test suite

The [fbp-protocol](https://github.com/flowbased/fbp-protocol) tool provides a set of tests for FBP protocol implementations.

## Changes

* 2015-11-20:
  - Initial `trace` subprotocol, for [Flowtrace](https://github.com/flowbased/flowtrace) support
* 2015-03-27:
  - Documented `network` `persist` and `component` `componentsready` messages
* 2015-03-26: Version 0.5
  - All messages sent to runtime should include the `secret` in payload
  - Runtime description message includes an `allCapabilities` array describing capabilities of the runtime, including ones not available to current user
* 2014-10-23
  - added clarifications to network running state in `status`, `started`, and `stopped` messages
* 2014-09-26
  - Add `secret` as payload to `getruntime` to support [access levels](https://github.com/noflo/noflo-ui/issues/278)
* 2014-08-05:
  - Add get, list, graph, graphsdone commands to the graph protocol
  - Add list, network commands to the network protocol
* 2014-07-15:
  - Add changenode, changeedge, addgroup, removegroup, renamegroup,
    changegroup commands to the graph protocol
* 2014-03-13: Version 0.4
  - Capability discovery support
  - Network exported port messaging for remote subgraphs
* 2014-02-18: Version 0.3
  - Support for exported graph ports
* 2014-01-09: Version 0.2
  - Multi-graph support via the `graph` key in payload
  - Harmonization with [JSON format](http://noflojs.org/documentation/json/) by renaming `from`/`to` in edges to `src`/`tgt`
  - Network `edges` message

## Basics

The FBP protocol is a message-based protocol that can be handled using various different transport mechanisms. The messages are designed to be independent, and not to form a request-response cycle in order to allow highly asynchronous operations and situations where multiple protocol clients talk with the same runtime.

There are currently three transports utilized commonly:

* [Web Messaging](http://en.wikipedia.org/wiki/Web_Messaging) (`postMessage`) for communication between different web pages or WebWorkers running inside the same browser instance
* [WebSocket](http://en.wikipedia.org/wiki/WebSocket) for communicating between a browser and a server, or between two server instances
* [WebRTC](http://en.wikipedia.org/wiki/WebRTC) for peer-to-peer communications between a runtime and a client

Different transports can be utilized as needed. It could be interesting to implement the FBP protocol using [MQTT](http://en.wikipedia.org/wiki/MQ_Telemetry_Transport), for instance.

### Sub-protocols

The FBP protocol is divided into four sub-protocols, or "channels":

* `runtime`: communications about runtime capabilities and its exported ports
* `graph`: communications about graph changes
* `component`: communications about available components and changes to them
* `network`: communications related to running a FBP graph
* `trace`: communications related to tracing a FBP network

### Message structure

This document describes all messages as the data structures that are passed. The way these are encoded depends on the transport being used. For example, with WebSockets all messages are encoded as stringified JSON.

All messages consist of three parts:

* Sub-protocol identifier (`graph`, `component`, or `network`)
* Topic (for example, `addnode`)
* Message payload (typically a data structure specific to the sub-protocol and topic)

The keys listed in specific messages are for the message payloads. The values are strings unless stated differently.

<a id="runtime"></a>
## Runtime protocol

When a client connects to a FBP procotol it may choose to discover the capabilities and other information about the runtime.

### `error

Runtime error


### `getruntime

Request the information about the runtime. When receiving this message the runtime should response with a runtime message.
* `secret`: access token to authorize user


### `packet

Runtimes that can be used as remote subgraphs (i.e. ones that have reported supporting the protocol:runtime capability) need to be able to receive and transmit information packets at their exposed ports. 
These packets can be send from the client to the runtimes input ports, or from runtimes output ports to the client.
* `port`: port name for the input or output port
* `event`: packet event
* `graph`: graph the action targets
* `payload`: (optional) payload for the packet. Used only with begingroup (for group names) and data packets
* `secret`: access token to authorize user


### `ports

Message sent by the runtime to signal its available ports. The runtime is responsible for sending the up-to-date list of available ports back to client whenever it changes.
* `graph`: ID of the currently configured main graph running on the runtime
* `inPorts`: list of input ports, each containing
  - `addressable`: boolean telling whether the port is an ArrayPort
  - `id`: port name
  - `type`: port datatype, for example boolean
  - `required`: boolean telling whether the port needs to be connected for the component to work
  - `description`: textual description of the port
* `inPorts`: list of input ports, each containing
* `outPorts`: list of output ports, each containing
  - `addressable`: boolean telling whether the port is an ArrayPort
  - `id`: port name
  - `type`: port datatype, for example boolean
  - `required`: boolean telling whether the port needs to be connected for the component to work
  - `description`: textual description of the port
* `outPorts`: list of output ports, each containing


### `runtime

Response from the runtime to the getruntime request.
* `id`: (optional) runtime ID used with Flowhub Registry
* `label`: (optional) Human-readable description of the runtime
* `version`: version of the runtime protocol that the runtime supports, for example 0.4
* `allCapabilities`: array of capability strings for things the runtime is able to do. May include things not permitted for the user. Options include:
  - `protocol:network`: the runtime is able to control and introspect its running networks using the Network protocol
  - `protocol:component`: the runtime is able to list and modify its components using the Component protocol
  - `protocol:runtime`: the runtime is able to expose the ports of its main graph using the Runtime protocol and transmit packet information to/from them
  - `component:getsource`: runtime is able to read and send component source code back to client
  - `network:persist`: runtime is able to *flash* a running graph setup into itself, making it persistent across reboots
  - `protocol:graph`: the runtime is able to modify its graphs using the Graph protocol
  - `component:setsource`: runtime is able to compile and run custom components sent as source code strings
* `capabilities`: array of capability strings for things the runtime is able to do. 
If the runtime is currently running a graph and it is able to speak the full Runtime protocol, it should follow up with a ports message. Options include:
  - `protocol:network`: the runtime is able to control and introspect its running networks using the Network protocol
  - `protocol:component`: the runtime is able to list and modify its components using the Component protocol
  - `protocol:runtime`: the runtime is able to expose the ports of its main graph using the Runtime protocol and transmit packet information to/from them
  - `component:getsource`: runtime is able to read and send component source code back to client
  - `network:persist`: runtime is able to *flash* a running graph setup into itself, making it persistent across reboots
  - `protocol:graph`: the runtime is able to modify its graphs using the Graph protocol
  - `component:setsource`: runtime is able to compile and run custom components sent as source code strings
* `graph`: (optional) ID of the currently configured main graph running on the runtime, if any
* `type`: type of the runtime, for example noflo-nodejs or microflo


<a id="graph"></a>
## Graph protocol

This protocol is utilized for communicating about graph changes in both directions.

### `error

Graph error


### `clear

Initialize an empty graph.
* `id`: identifier for the graph being created. Used for all subsequent messages related to the graph instance
* `name`: (optional) Human-readable label for the graph
* `library`: (optional) Component library identifier
* `main`: (optional) Identifies the graph as a main graph of a project that should not be registered as a component
Graphs registered in this way should also be available for use as subgraphs in other graphs. Therefore a graph registration and later changes to it may cause component messages of the Component protocol to be sent back to the client informing of possible changes in the ports of the subgraph component.
* `icon`: (optional) Icon to use for the graph when used as a component
* `description`: (optional) Description to use for the graph when used as a component
* `secret`: access token to authorize user


### `addnode

Add node to a graph.
* `id`: identifier for the node
* `component`: component name used for the node
* `metadata`: (optional): structure of key-value pairs for node metadata
* `graph`: graph the action targets
* `secret`: access token to authorize user


### `removenode

Remove a node from a graph.
* `id`: identifier for the node
* `graph`: graph the action targets
* `secret`: access token to authorize user


### `renamenode

Change the ID of a node in the graph
* `from`: original identifier for the node
* `to`: new identifier for the node
* `graph`: graph the action targets
* `secret`: access token to authorize user


### `changenode

Change the metadata associated to a node in the graph
* `id`: identifier for the node
* `metadata`: structure of key-value pairs for node metadata
* `graph`: graph the action targets
* `secret`: access token to authorize user


### `addedge

Add an edge to the graph
* `src`: source node for the edge
  - `node`: node identifier
  - `port`: port name
  - `index`: connection index (optional, for addressable ports)
* `src`: source node for the edge
* `tgt`: target node for the edge
  - `node`: node identifier
  - `port`: port name
  - `index`: connection index (optional, for addressable ports)
* `tgt`: target node for the edge
* `metadata`: (optional): structure of key-value pairs for edge metadata
* `graph`: graph the action targets
* `secret`: access token to authorize user


### `removeedge

Remove an edge from the graph
* `graph`: graph the action targets
* `src`: source node for the edge
  - `node`: node identifier
  - `port`: port name
  - `index`: connection index (optional, for addressable ports)
* `src`: source node for the edge
* `tgt`: target node for the edge
  - `node`: node identifier
  - `port`: port name
  - `index`: connection index (optional, for addressable ports)
* `tgt`: target node for the edge
* `secret`: access token to authorize user


### `changeedge

Change an edge's metadata
* `graph`: graph the action targets
* `metadata`: struct of key-value pairs for edge metadata
* `src`: source node for the edge
  - `node`: node identifier
  - `port`: port name
  - `index`: connection index (optional, for addressable ports)
* `src`: source node for the edge
* `tgt`: target node for the edge
  - `node`: node identifier
  - `port`: port name
  - `index`: connection index (optional, for addressable ports)
* `tgt`: target node for the edge
* `secret`: access token to authorize user


### `addinitial

Add an IIP to the graph
* `graph`: graph the action targets
* `metadata`: (optional): structure of key-value pairs for edge metadata
* `src`: undefined
  - `data`: IIP value in its actual data type
* `src`: undefined
* `tgt`: target node for the edge
  - `node`: node identifier
  - `port`: port name
  - `index`: connection index (optional, for addressable ports)
* `tgt`: target node for the edge
* `secret`: access token to authorize user


### `removeinitial

Remove an IIP from the graph
* `tgt`: target node for the edge
  - `node`: node identifier
  - `port`: port name
  - `index`: connection index (optional, for addressable ports)
* `tgt`: target node for the edge
* `graph`: graph the action targets
* `secret`: access token to authorize user


### `addinport

Add an exported inport to the graph.
* `public`: the exported name of the port
* `node`: node identifier
* `port`: internal port name
* `metadata`: (optional): structure of key-value pairs for node metadata
* `graph`: graph the action targets
* `secret`: access token to authorize user


### `removeinport

Remove an exported port from the graph
* `public`: the exported name of the port to remove
* `graph`: graph the action targets
* `secret`: access token to authorize user


### `renameinport

Rename an exported port in the graph
* `from`: original exported port name
* `to`: new exported port name
* `graph`: graph the action targets
* `secret`: access token to authorize user


### `addoutport

Add an exported outport to the graph.
* `public`: the exported name of the port
* `node`: node identifier
* `port`: internal port name
* `metadata`: (optional): structure of key-value pairs for port metadata
* `graph`: graph the action targets
* `secret`: access token to authorize user


### `removeoutport

Remove an exported port from the graph
* `public`: the exported name of the port to remove
* `graph`: graph the action targets
* `secret`: access token to authorize user


### `renameoutport

Rename an exported port in the graph
* `from`: original exported port name
* `to`: new exported port name
* `graph`: graph the action targets
* `secret`: access token to authorize user


### `addgroup

Add a group to the graph
* `name`: the group name
* `nodes`: an array of node ids part of the group
* `metadata`: (optional): structure of key-value pairs for group metadata
* `graph`: graph the action targets
* `secret`: access token to authorize user


### `removegroup

Remove a group from the graph
* `name`: the group name
* `graph`: graph the action targets
* `secret`: access token to authorize user


### `renamegroup

Rename a group in the graph.
* `from`: original group name
* `to`: new group name
* `graph`: graph the action targets
* `secret`: access token to authorize user


### `changegroup

Change a group's metadata
* `name`: the group name
* `metadata`: structure of key-value pairs for group metadata
* `graph`: graph the action targets
* `secret`: access token to authorize user


<a id="component"></a>
## Component protocol

Protocol for handling the component registry.

### `error

Component error


### `list

Request a list of currently available components. Will be responded with a set of `component` messages.
* `secret`: access token to authorize user


### `getsource

Request for the source code of a given component. Will be responded with a `source` message.
* `name`: Name of the component to for which to get source code
* `secret`: access token to authorize user


### `source

Source code for a component. In cases where a runtime receives a `source` message, it should do whatever operations are needed for making that component available for graphs, including possible compilation.
* `name`: Name of the component
* `language`: The programming language used for the component code, for example `coffeescript`
* `library`: (optional) Component library identifier
* `code`: Component source code
* `tests`: (optional) unit tests for the component


### `component

Transmit the metadata about a component instance.
* `name`: component name in format that can be used in graphs
* `description`: (optional) textual description on what the component does
* `icon`: (optional): visual icon for the component, matching icon names in [Font Awesome](http://fortawesome.github.io/Font-Awesome/icons/)
* `subgraph`: boolean telling whether the component is a subgraph
* `inPorts`: list of input ports, each containing:, each containing
  - `addressable`: boolean telling whether the port is an ArrayPort
  - `id`: port name
  - `type`: port datatype, for example boolean
  - `required`: boolean telling whether the port needs to be connected for the component to work
  - `description`: textual description of the port
* `inPorts`: list of input ports, each containing:, each containing
* `outPorts`: list of output ports, each containing
  - `addressable`: boolean telling whether the port is an ArrayPort
  - `id`: port name
  - `type`: port datatype, for example boolean
  - `required`: boolean telling whether the port needs to be connected for the component to work
  - `description`: textual description of the port
* `outPorts`: list of output ports, each containing


<a id="network"></a>
## Network protocol

Protocol for starting and stopping FBP networks, and finding out about their state.

### `error

An error from a running network, roughly similar to STDERR output of a Unix process, or a line of console.error in JavaScript.'
* `message`: contents of the error message


### `start

Start execution of a FBP network based on a given graph.
* `graph`: graph the action targets
* `secret`: access token to authorize user


### `getstatus

Get the current status of the runtime. The runtime should respond with a status message.
* `graph`: graph the action targets
* `secret`: access token to authorize user


### `stop

Stop execution of a FBP network based on a given graph.
* `graph`: graph the action targets
* `secret`: access token to authorize user


### `persist

Tells the runtime to persist the current state of graphs and components so that they are available between restarts. Requires the network:persist capability.
* `secret`: access token to authorize user


### `debug

Set a network into debug mode
* `enable`: tells whether to put the network in debug mode
* `graph`: graph the action targets
* `secret`: access token to authorize the user


### `edges

List of edges user has selected for inspection in a user interface or debugger, sent from UI to a runtime.
* `edges`: list of selected edges, each containing
  * `src`: source node for the edge
    - `node`: node identifier
    - `port`: port name
    - `index`: connection index (optional, for addressable ports)
  * `tgt`: target node for the edge
    - `node`: node identifier
    - `port`: port name
    - `index`: connection index (optional, for addressable ports)
* `edges`: list of selected edges, each containing
* `secret`: access token to authorize user


### `stopped

Inform that a given network has stopped.
* `time`: time when the network was stopped
* `uptime`: time the network was running, in seconds
* `graph`: graph the action targets
* `running`: whether or not network is currently running
* `started`: whether or not network has been started
* `debug`: whether or not network is in debug mode


### `started

Inform that a given network has been started.
* `time`: time when the network was started
* `graph`: graph the action targets
* `started`: whether or not network has started running
* `running`: whether or not network is currently running
* `debug`: whether or not network is in debug mode


### `status

Response to a getstatus message.
* `graph`: graph the action targets
* `uptime`: (optional) time the network has been running, in seconds
* `started`: whether or not network has started running
* `running`: boolean tells whether the network is running or not
* `debug`: whether or not network is in debug mode


### `output

An output message from a running network, roughly similar to STDOUT output of a Unix process, or a line of console.log in JavaScript. Output can also be used for passing images from the runtime to the UI.'
* `message`: contents of the output line
* `type`: (optional) type of output, either message or previewurl
* `url`: (optional) URL for an image generated by the runtime


### `processerror

When in debug mode, a network can signal an error happening inside a process.
* `id`: identifier of the node
* `error`: error from the component
* `graph`: graph the action targets


### `icon

Icon of a component instance has changed.
* `id`: identifier of the node
* `icon`: new icon for the component instance
* `graph`: graph the action targets


### `connect

Beginning of transmission on an edge.
* `id`: textual edge identifier, usually in form of a FBP language line
* `src`: source node for the edge
  - `node`: node identifier
  - `port`: port name
  - `index`: connection index (optional, for addressable ports)
* `src`: source node for the edge
* `tgt`: target node for the edge
  - `node`: node identifier
  - `port`: port name
  - `index`: connection index (optional, for addressable ports)
* `tgt`: target node for the edge
* `graph`: graph the action targets
* `subgraph`: (optional): subgraph identifier for the event. An array of node IDs


### `begingroup

Beginning of a group (bracket IP) on an edge.
* `id`: textual edge identifier, usually in form of a FBP language line
* `src`: source node for the edge
  - `node`: node identifier
  - `port`: port name
  - `index`: connection index (optional, for addressable ports)
* `src`: source node for the edge
* `tgt`: target node for the edge
  - `node`: node identifier
  - `port`: port name
  - `index`: connection index (optional, for addressable ports)
* `tgt`: target node for the edge
* `graph`: graph the action targets
* `subgraph`: (optional): subgraph identifier for the event. An array of node IDs


### `data

Data transmission on an edge.
* `id`: textual edge identifier, usually in form of a FBP language line
* `src`: source node for the edge
  - `node`: node identifier
  - `port`: port name
  - `index`: connection index (optional, for addressable ports)
* `src`: source node for the edge
* `tgt`: target node for the edge
  - `node`: node identifier
  - `port`: port name
  - `index`: connection index (optional, for addressable ports)
* `tgt`: target node for the edge
* `graph`: graph the action targets
* `subgraph`: (optional): subgraph identifier for the event. An array of node IDs


### `endgroup

Ending of a group (bracket IP) on an edge.
* `id`: textual edge identifier, usually in form of a FBP language line
* `src`: source node for the edge
  - `node`: node identifier
  - `port`: port name
  - `index`: connection index (optional, for addressable ports)
* `src`: source node for the edge
* `tgt`: target node for the edge
  - `node`: node identifier
  - `port`: port name
  - `index`: connection index (optional, for addressable ports)
* `tgt`: target node for the edge
* `graph`: graph the action targets
* `subgraph`: (optional): subgraph identifier for the event. An array of node IDs


### `disconnect

End of transmission on an edge.
* `id`: textual edge identifier, usually in form of a FBP language line
* `src`: source node for the edge
  - `node`: node identifier
  - `port`: port name
  - `index`: connection index (optional, for addressable ports)
* `src`: source node for the edge
* `tgt`: target node for the edge
  - `node`: node identifier
  - `port`: port name
  - `index`: connection index (optional, for addressable ports)
* `tgt`: target node for the edge
* `graph`: graph the action targets
* `subgraph`: (optional): subgraph identifier for the event. An array of node IDs


<a id="trace"></a>
## Tracing protocol

Protocol for creating [Flowtrace](https://github.com/flowbased/flowtrace)s. All these commands have `protocol: trace`.

### `start`

Enable/start tracing of a network.

* `secret`: access token to authorize the user
* `graph`: Graph identifier for network to trace
* `buffersize`: (optional) Size of tracing buffer to keep. In bytes

### `stop`

Stop/disable tracing of a network.

* `secret`: access token to authorize the user
* `graph`: Graph identifier for network to trace

### `dump`

Trigger dumping of the current tracing buffer, to return it back to server.

Request

* `secret`: access token to authorize the user
* `graph`: Graph identifier for network to trace
* `type`: String describing type of trace. Currently only `"flowtrace.json"` is supported.

Reply

* `graph`: Graph identifier for network to trace
* `type`: String describing type of trace. Currently only `"flowtrace.json"` is supported.
* `flowtrace`: A Flowtrace file of `type`, as a string.

### `clear`

Clear current tracing buffer.

* `secret`: access token to authorize the user
* `graph`: Graph identifier for network to trace

