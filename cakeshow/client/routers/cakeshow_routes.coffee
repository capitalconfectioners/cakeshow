models = require('models/registrant_models')

class exports.CakeshowRoutes extends Backbone.Router
	routes:
		'registrants': 'registrants'
		'registrants?:querystring': 'registrantsPage'
	
	registrants: ->
		app.registrants.reset()
		app.registrants.fetch(add: true)
	
	registrantsPage: (querystring) =>
		this.registrants()
