fs = require 'fs'
path = require 'path'

module.exports = ->
  # Project configuration
  @initConfig
    pkg: @file.readJSON 'package.json'

    # CoffeeScript compilation
    coffee:
      src:
        expand: true
        cwd: 'src'
        src: ['**.coffee']
        dest: 'src'
        ext: '.js'
      schema:
        expand: true
        cwd: 'schema'
        src: ['**.coffee']
        dest: 'schema'
        ext: '.js'
      test:
        expand: true
        cwd: 'test/schema/'
        src: ['**.coffee']
        dest: 'test/schema/'
        ext: '.js'

    convert:
      yaml:
        files: [
          expand: true
          cwd: 'schema/yaml'
          src: ['*.yml']
          dest: 'schema/json/'
          ext: '.json'
        ]

    # Automated recompilation and testing when developing
    watch:
      test:
        files: ['test/**/*.coffee', 'src/*.coffee', 'schema/*.coffee']
        tasks: ['test']
      yaml:
        files: ['schema/yaml/**/*.yml']
        tasks: ['convert', 'json-to-js', 'test']

    mochaTest:
      test:
        src: ['test/schema/*.js']
      options:
        greph: process.env.TESTS

    # FBP Network Protocol tests
    exec:
      fbp_test: 'node bin/fbp-test --colors'
      spechtml: 'node ./node_modules/.bin/showdown makehtml -i spec/protocol.md -o dist/index.html'

    # Deploying
    'gh-pages':
      options:
        base: 'dist/',
        user:
          name: 'fbp-protocol bot',
          email: 'jononor+fbpprotocolbot@gmail.com'
        silent: true
        repo: 'https://' + process.env.GH_TOKEN + '@github.com/flowbased/fbp-protocol.git'
      src: '**/*'

  # Grunt plugins used for testing
  @loadNpmTasks 'grunt-contrib-coffee'
  @loadNpmTasks 'grunt-contrib-watch'
  @loadNpmTasks 'grunt-exec'
  @loadNpmTasks 'grunt-mocha-test'

  # For deploying
  @loadNpmTasks 'grunt-gh-pages'

  # Create json schemas from yaml
  @loadNpmTasks 'grunt-convert'

  # Our local tasks
  @registerTask 'build', ['coffee', 'convert', 'json-to-js', 'build-markdown', 'exec:spechtml']
  @registerTask 'test', ['build', 'mochaTest'] # FIXME: enable 'exec:fbp_test'
  @registerTask 'default', ['test']

  @registerTask 'json-to-js', ->
    schemaJs = "module.exports = #{JSON.stringify getSchemas()}"
    fs.writeFileSync './schema/schemas.js', schemaJs, 'utf8'

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

  # transforms schemas into format better suited to be added to docs
  getDescriptions = ->
    tv4 = require './schema/index.js'
    schemas = getSchemas()

    fillRefs = (obj) ->
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

    desc = {}
    protocols =
      runtime: ['input', 'output']
      graph: ['input', 'output']
      component: ['input', 'output']
      network: ['input', 'output']

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
            for key, value of schema.allOf[1].properties.payload
              message[key] = value

          messages[event] = mergeAllOf message

    return desc

  @registerTask 'build-markdown', ->
    lines = []
    p = (line) -> lines.push line

    for protocol, protocolProps of getDescriptions()
      p "<a id=\"#{protocol}\"></a>"
      p "## #{protocolProps.title}\n"
      p "#{protocolProps.description}\n"

      for messageType, message of protocolProps.messages
        p "### `#{messageType}`\n"
        p "#{message.description}"

        for messagePropName, messageProp of message.properties
          line = "* `#{messagePropName}`: #{messageProp.description}"
          items = messageProp.items

          if messageProp.type is 'object' and messageProp.properties?
            p line
            for subPropName, subProp of messageProp.properties
              p "  - `#{subPropName}`: #{subProp.description}"

          if items?.type is 'object'
            line += ", each containing"
            p line

            for itemPropName, itemProp of items.properties
              if itemProp.type is 'object'
                p "  * `#{itemPropName}`: #{itemProp.description}"

                for itemSubPropName, itemSubProp of itemProp.properties
                  p "    - `#{itemSubPropName}`: #{itemSubProp.description}"

              else
                p "  - `#{itemPropName}`: #{itemProp.description}"

          if items?.type is 'string' and items?._enumDescriptions
            line += " Options include:"
            p line

            for enumDescription in items._enumDescriptions
              p "  - `#{enumDescription.name}`: #{enumDescription.description}"

          else
            p line

        p '\n'

    marker = "<%= descriptions %>\n"
    file = fs.readFileSync 'spec/protocol.js.md', 'utf8'
    file = file.replace marker, lines.join('\n')
    fs.writeFileSync 'spec/protocol.md', file, 'utf8'

