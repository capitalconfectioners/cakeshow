models = require('models/registrant_models')

class exports.CakeshowRoutes extends Backbone.Router
	routes:
		'registrants': 'registrants'
		'registrants?:querystring': 'registrantsPage'
	
	registrants: =>
		app.registrants.setUrl()
		this.reloadRegistrants()

	registrantsPage: (querystring) =>
		app.registrants.setUrl(querystring)
		this.reloadRegistrants()
	
	reloadRegistrants: ->
		app.registrants.reset()
		app.registrants.fetch(add: true)
