---
title: FBP Network Protocol
layout: documentation
permalink: index.html
---
The Flow-Based Programming network protocol (*FBP protocol*) has been designed primarily for flow-based programming interfaces like the [Flowhub](https://flowhub.io) to communicate with various FBP runtimes. However, it can also be utilized for communication between different runtimes, for example server-to-server or server-to-microcontroller.

## Implementations

Clients

* [noflo-ui](https://github.com/noflo/noflo-ui) is an open source visual IDE, which powers [Flowhub](http://flowhub.io)
* [fbp-spec](https://github.com/flowbased/fbp-spec) is a data-driven testing tool for FBP components/graphs.
* [fbp-protocol-client](https://github.com/flowbased/fbp-protocol-client) is a low-level JavaScript client library supporting all the common FBP protocol transports
* [fbp-client](https://github.com/flowbased/fbp-client) is a higher-level JavaScript client library supporting all the common FBP protocol transports

Runtimes

* [noflo-runtime-base](https://github.com/noflo/noflo-runtime-base) is a transport-independent implementation of the protocol for [NoFlo](http://noflojs.org), client-side and server-side JavaScript programming. WebSocket, WebRTC and iFrame implementations exists.
* [microflo](https://github.com/jonnor/microflo) is a WebSocket implementation of the protocol in JS/C++, for microcontrollers and embedded systems
* [Elixir FBP](http://www.elixirfbp.org/) is a WebSocket implementation in Elixir, for programming with systems in Elixir runnin on the Erlang VM.
* [imgflo](https://github.com/jonnor/imgflo) is a WebSocket implementation in C, for image processing
* [javafbp-runtime](https://github.com/jonnor/javafbp-runtime) is a Websocket implementation in Java for [JavaFBP](https://github.com/jpaulm/javafbp), for JRE and Android development
* [sndflo](https://github.com/jonnor/sndflo) is a WebSocket implementation for the SuperCollider audio programming environment
* [MsgFlo](https://github.com/the-grid/msgflo) is a Websocket implementation in Node.js for heterogenous distributed systems communicating via message queues
* [rill](https://github.com/PermaData/rill) is a Python FBP runtime implementation, with support for the protocol over WebSocket.

Some [examples](https://github.com/flowbased/protocol-examples) have also been created, to help implementors.

## Test suite

The [fbp-protocol](https://github.com/flowbased/fbp-protocol) tool provides a set of tests for FBP protocol implementations.

## Basics

The FBP protocol is a message-based protocol that can be handled using various different transport mechanisms. The messages are designed to be independent, and not to form a request-response cycle in order to allow highly asynchronous operations and situations where multiple protocol clients talk with the same runtime.

There are currently three transports utilized commonly:

* [Web Messaging](http://en.wikipedia.org/wiki/Web_Messaging) (`postMessage`) for communication between different web pages or WebWorkers running inside the same browser instance
* [WebSocket](http://en.wikipedia.org/wiki/WebSocket) for communicating between a browser and a server, or between two server instances
* [WebRTC](http://en.wikipedia.org/wiki/WebRTC) for peer-to-peer communications between a runtime and a client

Different transports can be utilized as needed. It could be interesting to implement the FBP protocol using [MQTT](http://en.wikipedia.org/wiki/MQ_Telemetry_Transport), for instance.

### Message structure

There are three types of messages in FBP Protocol:

1. Requests sent by client to runtime
2. Responses sent by runtime to client
3. Events sent by runtime to client unrelated to any request

This document describes all messages as the data structures that are passed. The way these are encoded depends on the transport being used. For example, with WebSockets all messages are encoded as stringified JSON.

All messages consist of three parts:

* Sub-protocol identifier (`graph`, `component`, or `network`)
* Topic (for example, `addnode`)
* Message payload (typically a data structure specific to the sub-protocol and topic)

Additionally requests made by clients include a unique `requestId` and optionally a `secret`. Responses sent by runtime include a `responseTo` referring to a request ID. Runtimes may also send messages on events that happen on the runtime without referring to a request ID.

The keys listed in specific messages are for the message `payload`.

An example message sent by a client:

```json
{
  "protocol": "graph",
  "command": "addnode",
  "payload": {
    "component": "canvas/Draw",
    "graph": "hello-canvas-example",
    "id": "draw",
    "metadata": {
      "label": "Draw onto canvas element"
    }
  },
  "secret": "fbp rocks",
  "requestId: "10259710-bc70-4d2c-b0b3-e78075d9b960"
}
```

Response to this could look like:

```json
{
  "protocol": "graph",
  "command": "addnode",
  "payload": {
    "component": "canvas/Draw",
    "graph": "hello-canvas-example",
    "id": "draw",
    "metadata": {
      "label": "Draw onto canvas element"
    }
  },
  "responseTo: "10259710-bc70-4d2c-b0b3-e78075d9b960"
}
```

### Sub-protocols

The FBP protocol is divided into sub-protocols for each of the major resources that can be manipulated:

* [`runtime`](#runtime-protocol): communications about runtime capabilities and its exported ports
* [`graph`](#graph-protocol): communications about graph changes
* [`component`](#component-protocol): communications about available components and changes to them
* [`network`](#network-protocol): communications related to running a FBP graph
* [`trace`](#trace-protocol): communications related to tracing a FBP network

### Capabilities

Not all runtimes implementation supports all features of the protocol. Also, a runtime may restrict *access* to features, either to all clients based on configuration, or based on the *secret* provided in the messages. To support this a set of **capabilities** are defined, which are reported by the runtime in the [runtime:runtime](#runtime-runtime) message.

When receiving a message, the runtime should check for the associated capability. If the capability is not supported, or the client does not have access to the capability, the runtime should respond with an `error` reply on the relevant `protocol`.

A few commands do not require any capabilities: the runtime info request/response ([runtime:getruntime](#runtime-getruntime) and [runtime:runtime](#runtime-runtime)), and the error responses ([runtime:error](#runtime-error), [graph:error](#graph-error), [network:error](#network-error), [component:error](#component-error)).

<%= capabilities %>

<%= messages %>

<%= changelog %>
