exports.index = (request, response) ->
  response.render('index', { title: 'Cakeshow' })

exports.registrants = (request, response) -> 
	registrantValues = (registrant.values for registrant in request.registrants)
	response.json(registrantValues)

exports.DatabaseMiddleware = class DatabaseMiddleware
	constructor: (cakeshowDB) ->
		this.cakeshowDB = cakeshowDB
	
	allRegistrants: (request, result, next) =>
		page = request.param('page',1)
		limit = request.param('page_size',25)
		
		offset = (page-1)*limit
		
		this.cakeshowDB.Registrant.findAll(offset:page, limit:limit, order: 'lastname ASC').success( (registrants) ->
			request.registrants = registrants
			next()
		)
		.error( (error) ->
			next(new Error('Could not load registrants: ' + error))
		)
			
