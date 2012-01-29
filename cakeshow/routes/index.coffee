exports.index = (request, response) ->
  response.render('index', { title: 'Express' })

exports.registrants = (request, response) -> 
	registrantValues = (registrant.values for registrant in request.registrants)
	response.json(registrantValues)

exports.DatabaseMiddleware = class DatabaseMiddleware
	constructor: (cakeshowDB) ->
		this.cakeshowDB = cakeshowDB
	
	allRegistrants: (request, result, next) =>
		this.cakeshowDB.Registrant.all().success( (registrants) ->
			request.registrants = registrants
			next()
		)
		.error( (error) ->
			next(new Error('Could not load registrants: ' + error))
		)
			
