/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const fs = require('fs');
const path = require('path');
const refParser = require('json-schema-ref-parser');

let schemas = null;
const getSchemas = function(callback) {
  if (!schemas) {
    schemas = {};
    const dir = './schema/json/';
    for (let jsonFile of Array.from(fs.readdirSync(dir))) {
      if (!['.', '..'].includes(jsonFile)) {
        const name = jsonFile.split('.')[0];
        const filename = path.join(dir, jsonFile);
        const schema = JSON.parse(fs.readFileSync(filename));
        schemas[name] = schema;
      }
    }
  }
  return refParser.dereference(schemas, callback);
};

var mergeAllOf = function(obj) {
  if (!obj) { return obj; }
  if ((typeof obj !== "object") || !(obj.length == null)) {
    return obj;
  }

  const newObj = {};
  for (let key in obj) {
    const value = obj[key];
    if (key === 'allOf') {
      for (let mergeObj of Array.from(obj[key])) {
        for (let propName in mergeObj) {
          const prop = mergeObj[propName];
          if (newObj[propName] == null) { newObj[propName] = prop; }
        }
      }
    }

    newObj[key] = mergeAllOf(value);
  }

  return newObj;
};

// transforms schemas into format better suited to be added to docs
const getDescriptions = function(schemas) {

  const desc = {};
  const protocols = {
    runtime: ['input', 'output'],
    graph: ['input'],
    component: ['input', 'output'],
    network: ['input', 'output'],
    trace: ['input', 'output']
  };

  for (let protocol in protocols) {
    const categories = protocols[protocol];
    const messages = {};
    desc[protocol] = {
      title: schemas[protocol].title,
      description: schemas[protocol].description,
      messages
    };

    for (let category of Array.from(categories)) {
      for (let event in schemas[protocol][category]) {
        const schema = schemas[protocol][category][event];
        const message = {
          id: schema.id,
          description: schema.description
        };

        if (schema.allOf != null) {
          //console.log 'sc', schema.allOf[1].properties
          for (let key in schema.allOf[1].properties.payload) {
            const value = schema.allOf[1].properties.payload[key];
            message[key] = value;
          }
        }

        //if event == 'error'
        //  console.log 'm', message
        messages[event] = mergeAllOf(message);
      }
    }
  }

  return desc;
};

const isAllowedTypeless = function(name, parent) {
  if ((parent.id === 'port_definition') && (name === 'default')) { return true; }
  if ((parent.id === 'input/packet') && (name === 'payload')) { return true; }
  if ((parent.id === 'output/packet') && (name === 'payload')) { return true; }
  if ((parent.id === 'output/packetsent') && (name === 'payload')) { return true; }
  return false;
};

const renderProperty = function(name, def, parent) {
  if (!def.description) { throw new Error(`Property ${name} is missing .description`); }
  if (!isAllowedTypeless(name, parent)) {
    if (!def.type) { throw new Error(`Property ${name} is missing .type`); }
  }
  if (!parent) { throw new Error(`Parent schema not specified for ${name}`); }
  if (parent.type === 'array') {
    if (!__guard__(parent.items != null ? parent.items.required : undefined, x => x.length)) {
      throw new Error(`.required array not specified for ${name} of ${parent.id} (array)`);
    }
  } else {
    if (((parent.required != null ? parent.required.length : undefined) == null)) {
      console.log(JSON.stringify(parent, null, 2));
      throw new Error(`.required array not specified for ${name} of ${parent.id}`);
    }
  }

  const isOptional = ((parent.type === 'array') && ((parent.required != null ? parent.required.indexOf(name) : undefined) === -1)) || (__guard__(parent.items != null ? parent.items.required : undefined, x1 => x1.indexOf(name)) === -1);
  let classes = "property";
  if (isOptional) { classes += " optional"; }
  name = `<label class='${classes} name'>${name}</label>`;
  const type = `<label class='${classes} type'>${def.type || 'any'}</label>`;

  if (def.enum != null ? def.enum.length : undefined) {
    def.description += ` (one of: ${def.enum.join(', ')})`;
  }

  const description = `<label class='${classes} description'>${def.description}</label>`;
  let example = "";
  if (def.example != null) { example = `<code class='${classes} example'>${JSON.stringify(def.example)}</code>`; }
  return name + type + description + example;
};

const renderMessage = function(messageType, message, protocolName) {

  const lines = [];
  const p = line => lines.push(line);

  const messageId = `${protocolName}-${messageType}`;
  const anchorUrl = '#'+messageId;

  p(`<h3 id='${messageId}' class='message name'><a href='${anchorUrl}'>${messageType}</a></h3>`);
  p(`<p>${message.description}</p>`);

  p("<ul class='message properties'>");
  for (let messagePropName in message.properties) {
    const messageProp = message.properties[messagePropName];
    let line = `<li>${renderProperty(messagePropName, messageProp, message)}</li>`;
    const {
      items
    } = messageProp;

    if ((messageProp.type === 'object') && (messageProp.properties != null)) {
      p(line);
      p("<ul class='properties'>");
      for (let subPropName in messageProp.properties) {
        const subProp = messageProp.properties[subPropName];
        p(`<li>${renderProperty(subPropName, subProp, messageProp)}</li>`);
      }
      p("</ul>");

    } else if ((items != null ? items.type : undefined) === 'object') {
      line += "Each item contains:";
      p(line);

      p("<ul class='properties'>");
      for (let itemPropName in items.properties) {
        const itemProp = items.properties[itemPropName];
        if (itemProp.type === 'object') {
          p(`<li>${renderProperty(itemPropName, itemProp, messageProp)}</li>`);

          p("<ul class='properties'>");
          for (let itemSubPropName in itemProp.properties) {
            const itemSubProp = itemProp.properties[itemSubPropName];
            p(`<li>${renderProperty(itemSubPropName, itemSubProp, itemProp)}</li>`);
          }
          p("</ul>");

        } else {
          p(`<li>${renderProperty(itemPropName, itemProp, messageProp)}</li>`);
        }
      }
      p("</ul>");

    } else {
      p(line);
    }
  }
  p("</ul>");

  return lines;
};

const renderCapabilities = function(callback) {
  const tv4 = require('../schema/index.js');
  const schema = tv4.getSchema('/shared/capabilities');

  const lines = [];
  const p = line => lines.push(line);
  p("<section class='capabilities'>");
  for (let enumDescription of Array.from(schema.items._enumDescriptions)) {
    var messageUrl, name;
    p(`<h4 class='capability name'>${enumDescription.name}</h4>`);
    p(`<p>${enumDescription.description}</p>`);

    p("<h5 class='capability messages header'>input messages</h5>");
    p("<ul class='capability messages'>");
    for (name of Array.from(enumDescription.inputs)) {
      messageUrl = "#"+name.replace(':', '-');
      p(`<li><a href='${messageUrl}'>${name}</a></li>`);
    }
    p("</ul>");

    p("<h5 class='capability messages header'>output messages</h5>");
    p("<ul class='capability messages'>");
    for (name of Array.from(enumDescription.outputs)) {
      messageUrl = "#"+name.replace(':', '-');
      p(`<li><a href='${messageUrl}'>${name}</a></li>`);
    }
    p("</ul>");
  }

  p("</section>");

  return callback(null, lines.join('\n'));
};

const renderMessages = callback => getSchemas(function(err, schemas) {
  if (err) { return callback(err); }
  const descriptions = getDescriptions(schemas);

  let lines = [];
  const p = line => lines.push(line);

  for (let protocol in descriptions) {
    const protocolProps = descriptions[protocol];
    p(`<h2 class='protocol name' id='${protocol}-protocol'>${protocolProps.title}</h2>`);
    p(`<p class='protocol description'>${protocolProps.description}</p>`);

    for (let messageType in protocolProps.messages) {
      const message = protocolProps.messages[messageType];
      const m = renderMessage(messageType, message, protocol);
      lines = lines.concat(m);
    }
  }

  return callback(null, lines.join('\n'));
});

module.exports = {
  renderMessages,
  renderCapabilities,
  getSchemas
};

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}