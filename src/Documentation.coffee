fs = require 'fs'
path = require 'path'

schemas = null
getSchemas = ->
  unless schemas
    schemas = {}
    dir = './schema/json/'
    for jsonFile in fs.readdirSync dir
      if jsonFile not in ['.', '..']
        name = jsonFile.split('.')[0]
        filename = path.join dir, jsonFile
        schema = JSON.parse fs.readFileSync filename
        schemas[name] = schema

  return schemas

fillRefs = (obj) ->
  tv4 = require '../schema/index.js'

  if typeof obj isnt 'object'
    return obj

  else if (typeof obj) is 'object' and obj.length?
    return obj.map (item) -> fillRefs item

  newObj = {}
  for own key, value of obj
    if key is '$ref'
      refObj = fillRefs tv4.getSchema(value)
      for own refKey, refValue of refObj
        newObj[refKey] = refValue

    else
      newObj[key] = fillRefs value

  return newObj

mergeAllOf = (obj) ->
  unless typeof obj is "object" and not obj.length?
    return obj

  newObj = {}
  for key, value of obj
    if key is 'allOf'
      for mergeObj in obj[key]
        for propName, prop of mergeObj
          newObj[propName] ?= prop

    else if typeof value is "object" and not value.length?
      newObj[key] = mergeAllOf value

    else
      newObj[key] = value

  return newObj

# transforms schemas into format better suited to be added to docs
getDescriptions = (schemas) ->

  desc = {}
  protocols =
    runtime: ['input', 'output']
    graph: ['input']
    component: ['input', 'output']
    network: ['input', 'output']
    trace: ['input', 'output']

  for protocol, categories of protocols
    messages = {}
    desc[protocol] =
      title: schemas[protocol].title
      description: schemas[protocol].description
      messages: messages

    for category in categories
      for event, schema of schemas[protocol][category]
        schema = fillRefs schema
        message =
          id: schema.id
          description: schema.description

        if schema.allOf?
          #console.log 'sc', schema.allOf[1].properties
          for key, value of schema.allOf[1].properties.payload
            message[key] = value

        #if event == 'error'
        #  console.log 'm', message
        messages[event] = mergeAllOf message

  return desc

isAllowedTypeless = (name, parent) ->
  return true if parent.id is '/shared/port_definition' and name is 'default'
  return true if parent.id is 'input/packet' and name is 'payload'
  false

renderProperty = (name, def, parent) ->
  throw new Error("Property #{name} is missing .description") if not def.description
  unless isAllowedTypeless name, parent
    throw new Error("Property #{name} is missing .type") if not def.type
  throw new Error("Parent schema not specified for #{name}") if not parent
  if parent.type == 'array'
    if not parent.items?.required?.length
      throw new Error(".required array not specified for #{name} of #{parent.id} (array)")
  else
    if not parent.required?.length?
      console.log(JSON.stringify(parent, null, 2))
      throw new Error(".required array not specified for #{name} of #{parent.id}")

  isOptional = (parent.type == 'array' and parent.required?.indexOf(name) == -1) or parent.items?.required?.indexOf(name) == -1
  classes = "property"
  classes += " optional" if isOptional
  name = "<label class='#{classes} name'>#{name}</label>"
  type = "<label class='#{classes} type'>#{def.type or 'any'}</label>"
  description = "<label class='#{classes} description'>#{def.description}</label>"
  example = ""
  example = "<code class='#{classes} example'>#{JSON.stringify(def.example)}</code>" if def.example?
  return name + type + description + example

renderMessage = (messageType, message, protocolName) ->

  lines = []
  p = (line) -> lines.push line

  messageId = "#{protocolName}-#{messageType}"
  anchorUrl = '#'+messageId

  p "<h3 id='#{messageId}' class='message name'><a href='#{anchorUrl}'>#{messageType}</a></h3>"
  p "<p>#{message.description}</p>"

  p "<ul class='message properties'>"
  for messagePropName, messageProp of message.properties
    line = "<li>#{renderProperty(messagePropName, messageProp, message)}</li>"
    items = messageProp.items

    if messageProp.type is 'object' and messageProp.properties?
      p line
      p "<ul class='properties'>"
      for subPropName, subProp of messageProp.properties
        p "<li>#{renderProperty(subPropName, subProp, messageProp)}</li>"
      p "</ul>"

    else if items?.type is 'object'
      line += "Each item contains:"
      p line

      p "<ul class='properties'>"
      for itemPropName, itemProp of items.properties
        if itemProp.type is 'object'
          p "<li>#{renderProperty(itemPropName, itemProp, messageProp)}</li>"

          p "<ul class='properties'>"
          for itemSubPropName, itemSubProp of itemProp.properties
            p "<li>#{renderProperty(itemSubPropName, itemSubProp, itemProp)}</li>"
          p "</ul>"

        else
          p "<li>#{renderProperty(itemPropName, itemProp, messageProp)}</li>"
      p "</ul>"

    else
      p line
  p "</ul>"

  return lines

renderCapabilities = () ->
  tv4 = require '../schema/index.js'
  schema = tv4.getSchema '/shared/capabilities'

  lines = []
  p = (line) -> lines.push line

  p "<section class='capabilities'>"
  for enumDescription in schema.items._enumDescriptions
    p "<h4 class='capability name'>#{enumDescription.name}</h4>"
    p "<p>#{enumDescription.description}</p>"

    p "<h5 class='capability messages header'>input messages</h5>"
    p "<ul class='capability messages'>"
    for name in enumDescription.inputs
      messageUrl = "#"+name.replace(':', '-')
      p "<li><a href='#{messageUrl}'>#{name}</a></li>"
    p "</ul>"

    p "<h5 class='capability messages header'>output messages</h5>"
    p "<ul class='capability messages'>"
    for name in enumDescription.outputs
      messageUrl = "#"+name.replace(':', '-')
      p "<li><a href='#{messageUrl}'>#{name}</a></li>"
    p "</ul>"

  p "</section>"

  return lines.join('\n')

renderMessages = () ->
  schemas = getSchemas()
  descriptions = getDescriptions schemas

  lines = []
  p = (line) -> lines.push line

  for protocol, protocolProps of descriptions
    p "<h2 class='protocol name'>#{protocolProps.title}</h2>"
    p "<p class='protocol description'>#{protocolProps.description}</p>"

    for messageType, message of protocolProps.messages
      m = renderMessage messageType, message, protocol
      lines = lines.concat m

  return lines.join('\n')

module.exports =
  renderMessages: renderMessages
  renderCapabilities: renderCapabilities
  getSchemas: getSchemas
