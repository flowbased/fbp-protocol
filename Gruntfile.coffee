fs = require 'fs'
path = require 'path'
documentation = require './src/Documentation'

module.exports = ->
  pkg = @file.readJSON 'package.json'
  # Project configuration
  @initConfig
    pkg: pkg

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

    # Building the website
    jekyll:
      options:
        src: 'spec/'
        dest: 'dist/'
        layouts: 'spec/_layouts'
      dist:
        options:
          dest: 'dist/'
      serve:
        options:
          dest: 'dist/'
          serve: true
          watch: true
          host: process.env.HOSTNAME or 'localhost'
          port: process.env.PORT or 4000

    # Deploying
    'gh-pages':
      options:
        base: 'dist/',
        clone: 'gh-pages'
        message: "Release #{pkg.name} #{process.env.TRAVIS_TAG}"
        repo: 'https://' + process.env.GH_TOKEN + '@github.com/flowbased/fbp-protocol.git'
        user:
          name: 'fbp-protocol bot',
          email: 'jononor+fbpprotocolbot@gmail.com'
        silent: true
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
  @loadNpmTasks 'grunt-jekyll'

  # Our local tasks
  @registerTask 'build', ['coffee', 'convert', 'json-to-js', 'build-markdown', 'jekyll:dist']
  @registerTask 'test', ['build', 'mochaTest'] # FIXME: enable 'exec:fbp_test'
  @registerTask 'default', ['test']

  @registerTask 'json-to-js', ->
    schemaJs = "module.exports = #{JSON.stringify documentation.getSchemas()}"
    fs.writeFileSync './schema/schemas.js', schemaJs, 'utf8'

  @registerTask 'build-markdown', ->
    markup = documentation.renderMarkdown() 

    marker = "<%= descriptions %>\n"
    file = fs.readFileSync 'spec/protocol.js.md', 'utf8'
    file = file.replace marker, markup
    fs.writeFileSync 'spec/protocol.md', file, 'utf8'

