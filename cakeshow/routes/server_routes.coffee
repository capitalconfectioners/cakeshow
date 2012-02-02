exports.index = (request, response, next) ->
	response.render('index', 
		title: 'Cakeshow'
		initialState: JSON.stringify(
			route: request.url
			link: response.header('Link')
			data: request.sanitizedRegistrants
		)
	)

exports.registrants = (request, response, next) -> 
	request.sanitizedRegistrants = []
	for registrant in request.registrants
		rawRegistrant = {}
		rawRegistrant[key]= value for key, value of registrant.values when key != 'password'
		request.sanitizedRegistrants.push(rawRegistrant)

	if request.next_page?
		link = "<#{request.route.path}?page=#{request.next_page}>; rel=\"next\""
	
	if request.prev_page?
		if link?
			link += ", "
		else
			link = ""
		
		link += "<#{request.route.path}?page=#{request.prev_page}>; rel=\"prev\""
	
	if link?
		response.header('Link', link)

	if request.accepts('json')
		response.json(request.sanitizedRegistrants)
	else
		next()

exports.DatabaseMiddleware = class DatabaseMiddleware
	constructor: (cakeshowDB) ->
		this.cakeshowDB = cakeshowDB
	
	allRegistrants: (request, result, next) =>
		page = parseInt(request.param('page','1'), 10)
		limit = parseInt(request.param('page_size','25'), 10)
		
		offset = (page-1)*limit
		
		this.cakeshowDB.Registrant.count().success( (count) =>
			request.total_registrants = count
			
			if page > 1 
				request.prev_page = page-1
			
			if offset + limit < count
				request.next_page = page+1
			
			this.cakeshowDB.Registrant.findAll(offset:offset, limit:limit, order: 'lastname ASC, firstname ASC').success( (registrants) ->
				request.registrants = registrants
				next()
			)
			.error( (error) ->
				next(new Error('Could not load registrants: ' + error))
			)
		)
		.error( (error) ->
			next(new Error('Could not count registrants: ' + error))
		)
			
