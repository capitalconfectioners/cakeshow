express = require('express')
routes = require('./routes')
cakeshowDB = require('./database/cakeshowDB')

app = module.exports = express.createServer();

cakeshowDB.connect()

# Configuration

app.configure( ->
  app.set('views', __dirname + '/views')
  app.set('view engine', 'jade')
  app.use(express.bodyParser())
  app.use(express.methodOverride())
  app.use(app.router)
  app.use(express.static(__dirname + '/public'))
)

app.configure('development', ->
  app.use(express.errorHandler({ dumpExceptions: true, showStack: true }))
)

app.configure('production', ->
  app.use(express.errorHandler())
)

# Routes

middleware = new routes.DatabaseMiddleware(cakeshowDB)

app.get('/', routes.index)
app.get('/registrants', middleware.allRegistrants, routes.registrants)

app.listen(3000)
console.log("Express server listening on port %d in %s mode", app.address().port, app.settings.env)
