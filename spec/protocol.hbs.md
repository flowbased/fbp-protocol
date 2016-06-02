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

{{#eachKey schemas}}

<a id="{{key}}"></a>

## {{value.title}}

{{value.description}}

{{#eachKey value.messages}}

### `{{key}}`

{{value.description}}

{{#eachKey value.properties}}
* `{{key}}`: {{value.description}}{{#if value.items}}, each containing:
{{#eachKey value.items.properties}}
{{#if (isObject value)}}
  * `{{key}}`: {{value.description}}
{{#eachKey value.properties}}
    - `{{key}}`: {{value.description}}
{{/eachKey}}
{{else}}
  - `{{key}}`: {{value.description}}
{{/if}}
{{/eachKey}}{{/if}}{{#if (isObject value)}}
{{#eachKey value.properties}}
  - `{{key}}`: {{value.description}}
{{/eachKey}}{{/if}}
{{/eachKey}}
{{/eachKey}}
{{/eachKey}}

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

# TEST

<a id="anothergraph"></a>
