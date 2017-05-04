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

renderMessage = (messageType, message) ->

  lines = []
  p = (line) -> lines.push line

  p "### #{messageType}\n"
  p "#{message.description}\n"

  for messagePropName, messageProp of message.properties
    line = "* `#{messagePropName}`: #{messageProp.description}"
    items = messageProp.items

    if messageProp.type is 'object' and messageProp.properties?
      p line
      for subPropName, subProp of messageProp.properties
        p "  - `#{subPropName}`: #{subProp.description}"

    else if items?.type is 'object'
      line += ", each containing"
      p line

      for itemPropName, itemProp of items.properties
        if itemProp.type is 'object'
          p "  * `#{itemPropName}`: #{itemProp.description}"

          for itemSubPropName, itemSubProp of itemProp.properties
            p "    - `#{itemSubPropName}`: #{itemSubProp.description}"

        else
          p "  - `#{itemPropName}`: #{itemProp.description}"

    else if items?.type is 'string' and items?._enumDescriptions
      line += " Options include:"
      p line

      for enumDescription in items._enumDescriptions
        p "  - `#{enumDescription.name}`: #{enumDescription.description}"

    else
      p line

  p '\n'
  return lines

renderMarkdown = () ->
  schemas = getSchemas()
  descriptions = getDescriptions schemas

  lines = []
  p = (line) -> lines.push line

  for protocol, protocolProps of descriptions
    p "## #{protocolProps.title}\n"
    p "#{protocolProps.description}\n"

    for messageType, message of protocolProps.messages
      m = renderMessage messageType, message
      lines = lines.concat m

  return lines.join('\n')

module.exports =
  renderMarkdown: renderMarkdown
  getSchemas: getSchemas
