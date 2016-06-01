(function() {
  var chai, schemas, tv4;

  chai = require('chai');

  schemas = require('../../schema/schemas.js');

  tv4 = require('tv4');

  describe('Test graph protocol schema on event', function() {
    before(function() {
      var graphSchema, sharedSchema;
      sharedSchema = schemas.shared;
      graphSchema = schemas.graph;
      tv4.addSchema('/shared/', sharedSchema);
      return tv4.addSchema('/graph/', graphSchema);
    });
    describe('addnode', function() {
      var schema;
      schema = '/graph/input/addnode';
      it('should have input schema', function() {
        return chai.expect(tv4.getSchema(schema)).to.exist;
      });
      it('should have output shema', function() {
        return chai.expect(tv4.getSchema(schema).properties).to.eql(tv4.getSchema('/graph/output/addnode').properties);
      });
      it('should validate event with required fields', function() {
        var event, res;
        event = {
          protocol: 'graph',
          command: 'addnode',
          payload: {
            id: 'node1',
            component: 'core/Kick',
            graph: 'mygraph'
          }
        };
        res = tv4.validate(event, schema);
        return chai.expect(res).to.be["true"];
      });
      it('should invalidate additional properties', function() {
        var event, res;
        event = {
          protocol: 'graph',
          command: 'addnode',
          payload: {
            id: 'node1',
            component: 'core/Kick',
            graph: 'mygraph',
            whatisthis: 'notallowed'
          }
        };
        res = tv4.validate(event, schema);
        return chai.expect(res).to.be["false"];
      });
      return it('should invalidate event without required fields', function() {
        var event, res;
        event = {
          protocol: 'graph',
          payload: {
            id: 'node1',
            component: 'core/Kick',
            graph: 'mygraph'
          }
        };
        res = tv4.validate(event, schema);
        chai.expect(res).to.be["false"];
        return event = {
          protocol: 'graph',
          command: 'removenode',
          payload: {
            id: 'node1',
            component: 'core/Kick',
            graph: 'mygraph'
          }
        };
      });
    });
    describe('removenode', function() {
      var schema;
      schema = '/graph/input/removenode';
      it('should have input schema', function() {
        return chai.expect(tv4.getSchema(schema)).to.exist;
      });
      it('should have output shema', function() {
        return chai.expect(tv4.getSchema(schema).properties).to.eql(tv4.getSchema('/graph/output/removenode').properties);
      });
      return it('should validate event with required fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'removenode',
          payload: {
            id: 'node1',
            graph: 'mygraph'
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["true"];
      });
    });
    describe('renamenode', function() {
      var schema;
      schema = '/graph/input/renamenode';
      it('should have input schema', function() {
        return chai.expect(tv4.getSchema(schema)).to.exist;
      });
      it('should have output shema', function() {
        return chai.expect(tv4.getSchema(schema).properties).to.eql(tv4.getSchema('/graph/output/renamenode').properties);
      });
      return it('should validate event with required fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'renamenode',
          payload: {
            from: 'node1',
            to: 'node2',
            graph: 'mygraph'
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["true"];
      });
    });
    describe('changenode', function() {
      var schema;
      schema = '/graph/input/changenode';
      it('should have input schema', function() {
        return chai.expect(tv4.getSchema(schema)).to.exist;
      });
      it('should have output shema', function() {
        return chai.expect(tv4.getSchema(schema).properties).to.eql(tv4.getSchema('/graph/output/changenode').properties);
      });
      it('should validate event with required fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'changenode',
          payload: {
            id: 'node1',
            graph: 'mygraph',
            metadata: {
              x: 5,
              y: -1000.1
            }
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["true"];
      });
      return it('should invalidate event without required fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'changenode',
          payload: {
            id: 'node1',
            graph: 'mygraph'
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["false"];
      });
    });
    describe('addedge', function() {
      var schema;
      schema = '/graph/input/addedge';
      it('should have input schema', function() {
        return chai.expect(tv4.getSchema(schema)).to.exist;
      });
      it('should have output schema', function() {
        return chai.expect(tv4.getSchema(schema).properties).to.eql(tv4.getSchema('/graph/output/addedge').properties);
      });
      it('should validate event with required fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'addedge',
          payload: {
            graph: 'mygraph',
            src: {
              node: 'node1',
              port: 'OUT'
            },
            tgt: {
              node: 'node2',
              port: 'IN'
            }
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["true"];
      });
      return it('should invalidate event without required fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'addedge',
          payload: {
            graph: 'mygraph',
            src: {
              port: 'OUT'
            },
            tgt: {
              port: 'IN'
            }
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["false"];
      });
    });
    describe('removeedge', function() {
      var schema;
      schema = '/graph/input/removeedge';
      it('should have input schema', function() {
        return chai.expect(tv4.getSchema(schema)).to.exist;
      });
      it('should have output schema', function() {
        return chai.expect(tv4.getSchema(schema).properties).to.eql(tv4.getSchema('/graph/output/removeedge').properties);
      });
      return it('should validate event with required fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'removeedge',
          payload: {
            graph: 'mygraph',
            src: {
              node: 'node1',
              port: 'OUT'
            },
            tgt: {
              node: 'node2',
              port: 'IN'
            }
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["true"];
      });
    });
    describe('changeedge', function() {
      var schema;
      schema = '/graph/input/changeedge';
      it('should have input schema', function() {
        return chai.expect(tv4.getSchema(schema)).to.exist;
      });
      it('should have output schema', function() {
        return chai.expect(tv4.getSchema(schema).properties).to.eql(tv4.getSchema('/graph/output/changeedge').properties);
      });
      return it('should validate event with required fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'changeedge',
          payload: {
            graph: 'mygraph',
            src: {
              node: 'node1',
              port: 'OUT'
            },
            tgt: {
              node: 'node2',
              port: 'IN'
            },
            metadata: {
              route: 1
            }
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["true"];
      });
    });
    describe('addinitial', function() {
      var schema;
      schema = '/graph/input/addinitial';
      it('should have input schema', function() {
        return chai.expect(tv4.getSchema(schema)).to.exist;
      });
      it('should have output shema', function() {
        return chai.expect(tv4.getSchema(schema).properties).to.eql(tv4.getSchema('/graph/output/addinitial').properties);
      });
      it('should validate event with required fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'addinitial',
          payload: {
            graph: 'mygraph',
            src: {
              data: 5
            },
            tgt: {
              node: 'node2',
              port: 'IN'
            }
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["true"];
      });
      return it('should invalidate event without required fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'addinitial',
          payload: {
            graph: 'mygraph',
            src: {},
            tgt: {
              port: 'IN',
              node: 'node2'
            }
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["false"];
      });
    });
    describe('removeinitial', function() {
      var schema;
      schema = '/graph/input/removeinitial';
      it('should have input shema', function() {
        return chai.expect(tv4.getSchema(schema)).to.exist;
      });
      it('should have output shema', function() {
        return chai.expect(tv4.getSchema(schema).properties).to.eql(tv4.getSchema('/graph/output/removeinitial').properties);
      });
      it('should validate event with required fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'removeinitial',
          payload: {
            graph: 'mygraph',
            tgt: {
              node: 'node2',
              port: 'IN'
            }
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["true"];
      });
      return it('should invalidate event with extra fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'removeinitial',
          payload: {
            graph: 'mygraph',
            src: {
              data: 5
            },
            tgt: {
              node: 'node2',
              port: 'IN'
            }
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["false"];
      });
    });
    describe('addinport', function() {
      var schema;
      schema = '/graph/input/addinport';
      it('should have input shema', function() {
        return chai.expect(tv4.getSchema(schema)).to.exist;
      });
      it('should have output schema', function() {
        return chai.expect(tv4.getSchema(schema).properties).to.eql(tv4.getSchema('/graph/output/addinport').properties);
      });
      it('should validate event with required fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'addinport',
          payload: {
            graph: 'mygraph',
            "public": 'IN',
            node: 'core/Kick',
            port: 'DATA'
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["true"];
      });
      return it('should invalidate event with extra fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'addinport',
          payload: {
            graph: 'mygraph',
            "public": 'IN',
            node: 'core/Kick',
            port: 'DATA',
            extra: 'doesntwork'
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["false"];
      });
    });
    describe('removeinport', function() {
      var schema;
      schema = '/graph/input/removeinport';
      it('should have input shema', function() {
        return chai.expect(tv4.getSchema(schema)).to.exist;
      });
      it('should have output schema', function() {
        return chai.expect(tv4.getSchema(schema).properties).to.eql(tv4.getSchema('/graph/output/removeinport').properties);
      });
      it('should validate event with required fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'removeinport',
          payload: {
            graph: 'mygraph',
            "public": 'IN'
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["true"];
      });
      return it('should invalidate event with extra fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'removeinport',
          payload: {
            graph: 'mygraph',
            "public": 'IN',
            node: 'core/Kick',
            port: 'DATA'
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["false"];
      });
    });
    describe('renameinport', function() {
      var schema;
      schema = '/graph/input/renameinport';
      it('should have input shema', function() {
        return chai.expect(tv4.getSchema(schema)).to.exist;
      });
      it('should have output schema', function() {
        return chai.expect(tv4.getSchema(schema).properties).to.eql(tv4.getSchema('/graph/output/renameinport').properties);
      });
      return it('should validate event with required fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'renameinport',
          payload: {
            graph: 'mygraph',
            from: 'IN',
            to: 'MORE_IN'
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["true"];
      });
    });
    describe('addoutport', function() {
      var schema;
      schema = '/graph/input/addoutport';
      it('should have input shema', function() {
        return chai.expect(tv4.getSchema(schema)).to.exist;
      });
      it('should have output schema', function() {
        return chai.expect(tv4.getSchema(schema).properties).to.eql(tv4.getSchema('/graph/output/addoutport').properties);
      });
      it('should validate event with required fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'addoutport',
          payload: {
            graph: 'mygraph',
            "public": 'OUT',
            node: 'core/Repeat',
            port: 'OUT'
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["true"];
      });
      return it('should invalidate event with extra fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'addoutport',
          payload: {
            graph: 'mygraph',
            "public": 'OUT',
            node: 'core/Repeat',
            port: 'OUT',
            extra: 'doesntwork'
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["false"];
      });
    });
    describe('removeoutport', function() {
      var schema;
      schema = '/graph/input/removeoutport';
      it('should have input shema', function() {
        return chai.expect(tv4.getSchema(schema)).to.exist;
      });
      it('should have output schema', function() {
        return chai.expect(tv4.getSchema(schema).properties).to.eql(tv4.getSchema('/graph/output/removeoutport').properties);
      });
      it('should validate event with required fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'removeoutport',
          payload: {
            graph: 'mygraph',
            "public": 'OUT'
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["true"];
      });
      return it('should invalidate event with extra fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'removeoutport',
          payload: {
            graph: 'mygraph',
            "public": 'OUT',
            node: 'core/Kick',
            port: 'DATA'
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["false"];
      });
    });
    describe('renameoutport', function() {
      var schema;
      schema = '/graph/input/renameoutport';
      it('should have input shema', function() {
        return chai.expect(tv4.getSchema(schema)).to.exist;
      });
      it('should have output schema', function() {
        return chai.expect(tv4.getSchema(schema).properties).to.eql(tv4.getSchema('/graph/output/renameoutport').properties);
      });
      return it('should validate event with required fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'renameoutport',
          payload: {
            graph: 'mygraph',
            from: 'OUT',
            to: 'MORE_OUT'
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["true"];
      });
    });
    describe('addgroup', function() {
      var schema;
      schema = '/graph/input/addgroup';
      it('should have input schema', function() {
        return chai.expect(tv4.getSchema(schema)).to.exist;
      });
      it('should have output shema', function() {
        return chai.expect(tv4.getSchema(schema).properties).to.eql(tv4.getSchema('/graph/output/addgroup').properties);
      });
      it('should validate event with required fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'addgroup',
          payload: {
            graph: 'mygraph',
            name: 'mygroup',
            nodes: ['Kick', 'Drop']
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["true"];
      });
      return it('should invalidate event with extra fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'addgroup',
          payload: {
            graph: 'mygraph',
            name: 'mygroup',
            nodes: ['Kick', 'Drop'],
            extra: 'nope'
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["false"];
      });
    });
    describe('removegroup', function() {
      var schema;
      schema = '/graph/input/removegroup';
      it('should have input shema', function() {
        return chai.expect(tv4.getSchema(schema)).to.exist;
      });
      it('should have output schema', function() {
        return chai.expect(tv4.getSchema(schema).properties).to.eql(tv4.getSchema('/graph/output/removegroup').properties);
      });
      return it('should validate event with required fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'removegroup',
          payload: {
            graph: 'mygraph',
            name: 'mygroup'
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["true"];
      });
    });
    describe('renamegroup', function() {
      var schema;
      schema = '/graph/input/renamegroup';
      it('should have input shema', function() {
        return chai.expect(tv4.getSchema(schema)).to.exist;
      });
      it('should have output schema', function() {
        return chai.expect(tv4.getSchema(schema).properties).to.eql(tv4.getSchema('/graph/output/renamegroup').properties);
      });
      return it('should validate event with required fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'renamegroup',
          payload: {
            graph: 'mygraph',
            from: 'mygroup',
            to: 'yourgroup'
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["true"];
      });
    });
    return describe('changegroup', function() {
      var schema;
      schema = '/graph/input/changegroup';
      it('should have input schema', function() {
        return chai.expect(tv4.getSchema(schema)).to.exist;
      });
      it('should have output shema', function() {
        return chai.expect(tv4.getSchema(schema).properties).to.eql(tv4.getSchema('/graph/output/changegroup').properties);
      });
      return it('should validate event with required fields', function() {
        var event;
        event = {
          protocol: 'graph',
          command: 'changegroup',
          payload: {
            graph: 'mygraph',
            name: 'mygroup',
            metadata: {}
          }
        };
        return chai.expect(tv4.validate(event, schema)).to.be["true"];
      });
    });
  });

}).call(this);
