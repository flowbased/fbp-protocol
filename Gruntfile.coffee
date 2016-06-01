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
  @loadNpmTasks 'grunt-convert'

  # Our local tasks
  @registerTask 'build', ['coffee', 'exec:spechtml', 'convert', 'json-to-js']
  @registerTask 'test', ['build', 'mochaTest', 'exec:fbp_test']
  @registerTask 'default', ['test']

  @registerTask 'json-to-js', ->
    schemas = {}
    dir = './schema/json/'
    for jsonFile in fs.readdirSync dir
      if jsonFile not in ['.', '..']
        name = jsonFile.split('.')[0]
        filename = path.join dir, jsonFile
        schema = JSON.parse fs.readFileSync filename
        schemas[name] = schema

    schemaJs = "module.exports = #{JSON.stringify schemas}"
    fs.writeFileSync './schema/schemas.js', schemaJs, 'utf8'

