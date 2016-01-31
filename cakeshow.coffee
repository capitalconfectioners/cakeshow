express = require('express')

stitch = require('stitch')
require('./lib/stitch_jade').register(stitch)

routes = require('./routes/server_routes')
cakeshowDB = require('./database/cakeshowDB')

clientPackage = stitch.createPackage(
  paths: [ __dirname + '/client', __dirname + '/shared' ]
)

app = module.exports = express.createServer();

if process.env['JAWSDB_URL']
  parsedURI = process.env['JAWSDB_URL'].match(/mysql:\/\/(\w+):(\w+)@([^:]+):(\d+)\/(\w+)/)
  username = parsedURI[1]
  password = parsedURI[2]
  host = parsedURI[3]
  port = parseInt(parsedURI[4])
  database = parsedURI[5]
else
  database = process.env['CAKESHOW_DB'] ? 'cakeshow'
  username = process.env['CAKESHOW_USER'] ? 'root'
  password = process.env['CAKESHOW_PASSWORD'] ? ''

  host = 'localhost'
  port = 3306

cakeshowDB.connect(database, username, password,
  host: host
  port: port
)

# Configuration

app.configure( ->
  app.set('views', __dirname + '/views')
  app.set('view engine', 'jade')
  app.use(express.logger(format: ':method :url', immediate: true))
  app.use(express.bodyParser())
  app.use(express.methodOverride())
  app.use(express.compiler(src: __dirname + '/public', enable: ['less']))
  app.use(express.static(__dirname + '/public'))
  app.use((request, response, next) ->
    response.header('Cache-Control', 'no-cache')
    next()
  )
  app.use(app.router)
)

app.configure('development', ->
  app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))
)

app.configure('production', ->
  app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))
)

# Routes

app.get('/cakeshow.js', clientPackage.createServer())

routes.register(app, cakeshowDB)

port = (process.env.PORT || 3000)
# host = 'localhost'

#app.listen(port, host)
app.listen(port)

console.log("Express server listening on port %d in %s mode", port, app.settings.env)

log = (request, response, next) ->
  console.log('Request at ' + request.originalUrl)
  next()
