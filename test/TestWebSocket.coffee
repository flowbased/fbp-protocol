tests = require '../src/WebSocket'
lib = require '../src/Config'


# storedPath = lib.getStoredPath()
# fs.exists storedPath, (exists) ->
#   if exists
#     fs.readFile storedPath, (err, data) ->
#       if err
#         throw err
#       opts = JSON.parse data
#       tests.testRuntimeCommand(
#         opts.name,
#         opts.command,
#         opts.port,
#         opts.collection
#       )
#   else
#     throw new Error('Run fpb-init first to configure');

opts = lib.getStored()
tests.testRuntimeCommand(
  opts.name,
  opts.command,
  opts.host,
  opts.port,
  opts.collection,
  opts.version
)
