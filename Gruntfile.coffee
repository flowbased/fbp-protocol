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
      fbp_test:
        command: 'node ../bin/fbp-test --colors'
        options:
          cwd: 'test/'

  # Grunt plugins used for testing
  @loadNpmTasks 'grunt-contrib-coffee'
  @loadNpmTasks 'grunt-contrib-watch'
  @loadNpmTasks 'grunt-exec'

  # Our local tasks
  @registerTask 'build', ['coffee']
  @registerTask 'test', ['exec']
  @registerTask 'default', ['test']
