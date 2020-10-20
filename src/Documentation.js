const fs = require('fs');
const path = require('path');
// eslint-disable-next-line import/no-extraneous-dependencies
const refParser = require('json-schema-ref-parser');
const tv4 = require('../schema/index.js');

function getSchemas(callback) {
  let schemas;
  if (!schemas) {
    schemas = {};
    const dir = './schema/json/';
    fs.readdirSync(dir).forEach((jsonFile) => {
      if (!['.', '..'].includes(jsonFile)) {
        const name = jsonFile.split('.')[0];
        const filename = path.join(dir, jsonFile);
        const schema = JSON.parse(fs.readFileSync(filename));
        schemas[name] = schema;
      }
    });
  }
  refParser.dereference(schemas, callback);
}

function mergeAllOf(obj) {
  if (!obj) { return obj; }
  if ((typeof obj !== 'object') || !(obj.length == null)) {
    return obj;
  }

  const newObj = {};
  Object.keys(obj).forEach((key) => {
    const value = obj[key];
    if (key === 'allOf') {
      obj[key].forEach((mergeObj) => {
        Object.keys(mergeObj).forEach((propName) => {
          const prop = mergeObj[propName];
          if (newObj[propName] == null) { newObj[propName] = prop; }
        });
      });
    }

    newObj[key] = mergeAllOf(value);
  });

  return newObj;
}

// transforms schemas into format better suited to be added to docs
function getDescriptions(schemas) {
  const desc = {};
  const protocols = {
    runtime: ['input', 'output'],
    graph: ['input'],
    component: ['input', 'output'],
    network: ['input', 'output'],
    trace: ['input', 'output'],
  };

  Object.keys(protocols).forEach((protocol) => {
    const categories = protocols[protocol];
    const messages = {};
    desc[protocol] = {
      title: schemas[protocol].title,
      description: schemas[protocol].description,
      messages,
    };

    categories.forEach((category) => {
      Object.keys(schemas[protocol][category]).forEach((event) => {
        const schema = schemas[protocol][category][event];
        const message = {
          id: schema.id,
          description: schema.description,
        };

        if (schema.allOf != null) {
          Object.keys(schema.allOf[1].properties.payload).forEach((key) => {
            const value = schema.allOf[1].properties.payload[key];
            message[key] = value;
          });
        }

        // if event == 'error'
        //  console.log 'm', message
        messages[event] = mergeAllOf(message);
      });
    });
  });

  return desc;
}

function isAllowedTypeless(name, parent) {
  if ((parent.id === 'port_definition') && (name === 'default')) { return true; }
  if ((parent.id === 'input/packet') && (name === 'payload')) { return true; }
  if ((parent.id === 'output/packet') && (name === 'payload')) { return true; }
  if ((parent.id === 'output/packetsent') && (name === 'payload')) { return true; }
  return false;
}

function renderProperty(n, d, parent) {
  const def = d;
  let name = n;
  if (!def.description) { throw new Error(`Property ${name} is missing .description`); }
  if (!isAllowedTypeless(name, parent)) {
    if (!def.type) { throw new Error(`Property ${name} is missing .type`); }
  }
  if (!parent) { throw new Error(`Parent schema not specified for ${name}`); }
  if (parent.type === 'array') {
    if (!parent.items || !parent.items.required || !parent.items.required.length) {
      throw new Error(`.required array not specified for ${name} of ${parent.id} (array)`);
    }
  } else if (((parent.required != null ? parent.required.length : undefined) == null)) {
    console.log(JSON.stringify(parent, null, 2));
    throw new Error(`.required array not specified for ${name} of ${parent.id}`);
  }

  const isOptional = ((parent.type === 'array') && ((parent.required != null ? parent.required.indexOf(name) : undefined) === -1)) || (parent.items && parent.items.required && parent.items.required.indexOf(name) === -1);
  let classes = 'property';
  if (isOptional) { classes += ' optional'; }
  name = `<label class='${classes} name'>${name}</label>`;
  const type = `<label class='${classes} type'>${def.type || 'any'}</label>`;

  if (def.enum != null ? def.enum.length : undefined) {
    def.description += ` (one of: ${def.enum.join(', ')})`;
  }

  const description = `<label class='${classes} description'>${def.description}</label>`;
  let example = '';
  if (def.example != null) { example = `<code class='${classes} example'>${JSON.stringify(def.example)}</code>`; }
  return name + type + description + example;
}

function renderMessage(messageType, message, protocolName) {
  const lines = [];
  const p = (line) => lines.push(line);

  const messageId = `${protocolName}-${messageType}`;
  const anchorUrl = `#${messageId}`;

  p(`<h3 id='${messageId}' class='message name'><a href='${anchorUrl}'>${messageType}</a></h3>`);
  p(`<p>${message.description}</p>`);

  if (!message.properties) {
    return lines;
  }

  p("<ul class='message properties'>");
  Object.keys(message.properties).forEach((messagePropName) => {
    const messageProp = message.properties[messagePropName];
    let line = `<li>${renderProperty(messagePropName, messageProp, message)}</li>`;
    const {
      items,
    } = messageProp;

    if ((messageProp.type === 'object') && (messageProp.properties != null)) {
      p(line);
      p("<ul class='properties'>");
      Object.keys(messageProp.properties).forEach((subPropName) => {
        const subProp = messageProp.properties[subPropName];
        p(`<li>${renderProperty(subPropName, subProp, messageProp)}</li>`);
      });
      p('</ul>');
    } else if ((items != null ? items.type : undefined) === 'object') {
      line += 'Each item contains:';
      p(line);

      p("<ul class='properties'>");
      Object.keys(items.properties).forEach((itemPropName) => {
        const itemProp = items.properties[itemPropName];
        if (itemProp.type === 'object') {
          p(`<li>${renderProperty(itemPropName, itemProp, messageProp)}</li>`);

          p("<ul class='properties'>");
          Object.keys(itemProp.properties).forEach((itemSubPropName) => {
            const itemSubProp = itemProp.properties[itemSubPropName];
            p(`<li>${renderProperty(itemSubPropName, itemSubProp, itemProp)}</li>`);
          });
          p('</ul>');
        } else {
          p(`<li>${renderProperty(itemPropName, itemProp, messageProp)}</li>`);
        }
      });
      p('</ul>');
    } else {
      p(line);
    }
  });
  p('</ul>');

  return lines;
}

function renderCapabilities(callback) {
  const schema = tv4.getSchema('/shared/capabilities');

  const lines = [];
  const p = (line) => lines.push(line);
  p("<section class='capabilities'>");
  // eslint-disable-next-line
  schema.items._enumDescriptions.forEach((enumDescription) => {
    p(`<h4 class='capability name'>${enumDescription.name}</h4>`);
    p(`<p>${enumDescription.description}</p>`);

    p("<h5 class='capability messages header'>input messages</h5>");
    p("<ul class='capability messages'>");
    enumDescription.inputs.forEach((name) => {
      const messageUrl = `#${name.replace(':', '-')}`;
      p(`<li><a href='${messageUrl}'>${name}</a></li>`);
    });
    p('</ul>');

    p("<h5 class='capability messages header'>output messages</h5>");
    p("<ul class='capability messages'>");
    enumDescription.outputs.forEach((name) => {
      const messageUrl = `#${name.replace(':', '-')}`;
      p(`<li><a href='${messageUrl}'>${name}</a></li>`);
    });
    p('</ul>');
  });

  p('</section>');

  return callback(null, lines.join('\n'));
}

function renderMessages(callback) {
  getSchemas((err, schemas) => {
    if (err) {
      callback(err);
      return;
    }
    const descriptions = getDescriptions(schemas);

    let lines = [];
    const p = (line) => lines.push(line);

    Object.keys(descriptions).forEach((protocol) => {
      const protocolProps = descriptions[protocol];
      p(`<h2 class='protocol name' id='${protocol}-protocol'>${protocolProps.title}</h2>`);
      p(`<p class='protocol description'>${protocolProps.description}</p>`);

      Object.keys(protocolProps.messages).forEach((messageType) => {
        const message = protocolProps.messages[messageType];
        const m = renderMessage(messageType, message, protocol);
        lines = lines.concat(m);
      });
    });

    callback(null, lines.join('\n'));
  });
}

module.exports = {
  renderMessages,
  renderCapabilities,
  getSchemas,
};
