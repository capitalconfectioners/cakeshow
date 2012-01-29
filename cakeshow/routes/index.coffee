exports.index = (request, response) ->
  response.render('index', { title: 'Express' })

exports.registrants = (request, response) -> 
	response.json(request.registrants)
	