## Changes

* 2019-10-09:
  - Documented how runtimes can advertise themselves using mDNS
* 2018-08-18: **Version 0.8**
  - Moved `secret` from payload to message top-level
  - Introduced `requestId` and `responseTo` top-level keys for identifying requests and the response packets to them
* 2018-03-27:
  - Added schema for `network:edges` output message
  - Modified `subgraph` key of `network:data` and other network packet events to be an array as specified in the text
* 2018-03-26:
  - Fixed documentation for `component:setsource` to use `component:source` input, and `component:component` output
  - Added schema for `trace:error` message
  - Added `:error` output to all capabilities where user can perform actions that may fail
* 2018-03-23:
  - Added optional `graph` key to `network:error` payloads
* 2018-03-22: **Version 0.7**
  - Added `network:debug` and `network:getstatus` to the `network:control` permission
* 2018-03-21:
  - Fixed signature of `runtime:packet.payload`, `runtime:packetsent.payload`, and port definition `default` to accept any payload type
  - Added `values` and `default` keys for port definitions
  - Added schema for `component:componentsready` output message
  - Added schema for `graph:clear` output message
  - Added `packetsent` response for `runtime:packet` input message
* 2017-09-17:
  - Added `schema` support for ports and packets
  - Documented known metadata keys for various graph entities
* 2017-04-09: **Version 0.6**
  - Version 0.6. No breaking changes over 0.5.
  - Added additional capabilities `graph:readonly`, `network:control`, `network:data`, `network:status`. Especially useful for read-only access.
  - Deprecated the `protocol:network` capability in favor of the new fine-gained `network:*` capabilities.
  - Each capability now defines the set of messages contained in it. Available as `inputs` and `outputs` in the schema `/shared/capabilities`.
* 2017-05-04:
  - Fixed protocol errors (`graph:error`, `component:error` and `runtime:error`) to have mandatory `message` string payload.
  - Fixed missing `required` markers in some JSON schemas for `graph` protocol. Affected messages:
`graph:renamegroup`, `graph:renameinport`, `graph:removeinport`, `graph:addinitial`, `graph:changeedge`
  - More readable HTML output, including property value types and examples
* 2017-05-03:
  - Added more optional metadata to `runtime:runtime` message: `repository`, `repositoryVersion` and `namespace`
* 2017-02-20:
  - Fixed payload definition of `network:edges` missing mandatory `graph` key
* 2016-07-01:
  - `network:error` payload may now contain an optional `stacktrace`
* 2016-06-23:
  - Trace subprotocol also available in machine-readable format
* 2016-06-17:
  - Protocol definition available as machine-readable JSON [schemas](https://github.com/flowbased/fbp-protocol/tree/master/schema/yaml).
  - The human-readable HTML documentation is generated from this defintion.
  - The npm package `fbp-protocol` contains the schemas as YAML, JSON and .js modules.
* 2015-11-20:
  - Initial `trace` subprotocol, for [Flowtrace](https://github.com/flowbased/flowtrace) support
* 2015-03-27:
  - Documented `network` `persist` and `component` `componentsready` messages
* 2015-03-26: **Version 0.5**
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
* 2014-03-13: **Version 0.4**
  - Capability discovery support
  - Network exported port messaging for remote subgraphs
* 2014-02-18: **Version 0.3**
  - Support for exported graph ports
* 2014-01-09: **Version 0.2**
  - Multi-graph support via the `graph` key in payload
  - Harmonization with [JSON format](http://noflojs.org/documentation/json/) by renaming `from`/`to` in edges to `src`/`tgt`
  - Network `edges` message
