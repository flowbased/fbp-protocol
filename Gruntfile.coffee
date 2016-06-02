fs = require 'fs'
path = require 'path'
hbs = require 'handlebars'

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
  @registerTask 'build', ['coffee', 'convert', 'json-to-js', 'handlebars', 'exec:spechtml']
  @registerTask 'test', ['build', 'mochaTest', 'exec:fbp_test']
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

    desc = {}
    protocols =
      runtime: ['input', 'output']
      graph: ['input']
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

          messages[event] = message

    return desc

  @registerTask 'handlebars', ->
    hbs.registerHelper 'eachKey', (obj, options) ->
      out = ''
      for own key, value of obj
        out += options.fn {key, value}

      out

    hbs.registerHelper 'isObject', (obj) ->
      return (obj?.type is 'object') and obj.properties?

    hbs.registerHelper 'isStringEnum', (obj) ->
      return (obj?.type is 'string') and obj?.enums?

    file = fs.readFileSync 'spec/protocol.hbs.md', 'utf8'
    result = hbs.compile(file) {schemas: getDescriptions()}
    fs.writeFileSync 'spec/protocol.md', result, 'utf8'

