const fs = require('fs');
const documentation = require('./src/Documentation');

const runtimeSecret = process.env.FBP_PROTOCOL_SECRET || 'noflo';

module.exports = function () {
  const pkg = this.file.readJSON('package.json');
  // Project configuration
  this.initConfig({
    pkg,

    yaml: {
      options: {
        strict: true,
      },
      schemas: {
        files: [{
          expand: true,
          cwd: 'schema/yaml',
          src: ['*.yml'],
          dest: 'schema/json/',
          ext: '.json',
        },
        ],
      },
    },

    // Automated recompilation and testing when developing
    watch: {
      test: {
        files: ['test/**/*.js', 'src/*.js', 'schema/*.js'],
        tasks: ['test'],
      },
      yaml: {
        files: ['schema/yaml/**/*.yml'],
        tasks: ['yaml', 'json-to-js', 'test'],
      },
    },

    mochaTest: {
      test: {
        src: ['test/schema/*.js'],
      },
      options: {
        greph: process.env.TESTS,
      },
    },

    // FBP Network Protocol tests
    exec: {
      preheat_noflo_cache: './node_modules/.bin/noflo-cache-preheat',
      fbp_init_noflo: `node bin/fbp-init --command "noflo-nodejs --secret=${runtimeSecret} --host localhost --port=8080 --open=false" --name="NoFlo Node.js"`,
      fbp_test: {
        command: 'node bin/fbp-test --colors',
        options: {
          env: {
            FBP_PROTOCOL_SECRET: runtimeSecret,
            PATH: process.env.PATH,
          },
        },
      },
    },

    // Building the website
    jekyll: {
      options: {
        src: 'spec/',
        dest: 'dist/',
        layouts: 'spec/_layouts',
      },
      dist: {
        options: {
          dest: 'dist/',
        },
      },
      serve: {
        options: {
          dest: 'dist/',
          serve: true,
          watch: true,
          host: process.env.HOSTNAME || 'localhost',
          port: process.env.PORT || 4000,
        },
      },
    },
  });

  // Grunt plugins used for testing
  this.loadNpmTasks('grunt-contrib-watch');
  this.loadNpmTasks('grunt-exec');
  this.loadNpmTasks('grunt-mocha-test');

  // Create json schemas from yaml
  this.loadNpmTasks('grunt-yaml');
  this.loadNpmTasks('grunt-jekyll');

  // Our local tasks
  this.registerTask('build', [
    'yaml',
    'json-to-js',
    'build-markdown',
    'jekyll:dist',
  ]);
  this.registerTask('test', [
    'build',
    'mochaTest',
    'exec:preheat_noflo_cache',
    'exec:fbp_init_noflo',
    'exec:fbp_test',
  ]);
  this.registerTask('default', ['test']);

  this.registerTask('json-to-js', function () {
    const done = this.async();
    documentation.getSchemas((err, schemas) => {
      if (err) {
        done(err);
        return;
      }
      const schemaJs = `module.exports = ${JSON.stringify(schemas)}`;
      fs.writeFileSync('./schema/schemas.js', schemaJs, 'utf8');
      done();
    });
  });

  this.registerTask('build-markdown', function () {
    const done = this.async();
    documentation.renderMessages((err, messages) => {
      if (err) {
        done(err);
        return;
      }
      documentation.renderCapabilities((err2, capabilities) => {
        if (err2) {
          done(err2);
          return;
        }
        const changelog = fs.readFileSync('CHANGES.md', 'utf8');
        let file = fs.readFileSync('spec/protocol.js.md', 'utf8');
        file = file.replace('<%= messages %>\n', messages);
        file = file.replace('<%= capabilities %>', capabilities);
        file = file.replace('<%= changelog %>', changelog);
        fs.writeFileSync('spec/protocol.md', file, 'utf8');
        done();
      });
    });
  });
};
