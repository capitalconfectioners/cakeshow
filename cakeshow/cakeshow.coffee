express = require('express')
stitch = require('stitch')
routes = require('./routes/server_routes')
cakeshowDB = require('./database/cakeshowDB')

clientPackage = stitch.createPackage(
	paths: [ __dirname + '/client' ]
)

app = module.exports = express.createServer();

cakeshowDB.connect()

# Configuration

app.configure( ->
  app.set('views', __dirname + '/views')
  app.set('view engine', 'jade')
  app.use(express.bodyParser())
  app.use(express.methodOverride())
  app.use(express.static(__dirname + '/public'))
  app.use(app.router)
)

app.configure('development', ->
  app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))
)

app.configure('production', ->
  app.use(express.errorHandler())
)

# Routes
app.get('/cakeshow.js', clientPackage.createServer())

middleware = new routes.DatabaseMiddleware(cakeshowDB)

app.get('*', routes.index)
app.get('/registrants', middleware.allRegistrants, routes.registrants)

app.listen(3000)
console.log("Express server listening on port %d in %s mode", app.address().port, app.settings.env)
