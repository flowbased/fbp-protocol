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

    # Automated recompilation and testing when developing
    watch:
      files: ['test/*.coffee', 'src/*.coffee']
      tasks: ['test']

    # FBP Network Protocol tests
    exec:
      fbp_test: 'node bin/fbp-test --colors'
      spechtml: 'node ./node_modules/.bin/showdown makehtml -i spec/protocol.md -o dist/index.html'

    # Deploying
    'gh-pages':
      options:
        base: 'dist/',
        user:
          name: 'fbp-spec bot',
          email: 'jononor+fbpprotocolbot@gmail.com'
        silent: true
        repo: 'https://' + process.env.GH_TOKEN + '@github.com/flowbased/fbp-protocol.git'
      src: '**/*'

  # Grunt plugins used for testing
  @loadNpmTasks 'grunt-contrib-coffee'
  @loadNpmTasks 'grunt-contrib-watch'
  @loadNpmTasks 'grunt-exec'

  # For deploying
  @loadNpmTasks 'grunt-gh-pages'

  # Our local tasks
  @registerTask 'build', ['coffee', 'exec:spechtml']
  @registerTask 'test', ['build', 'exec:fbp_test']
  @registerTask 'default', ['test']
