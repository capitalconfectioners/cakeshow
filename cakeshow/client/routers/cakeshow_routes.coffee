class exports.CakeshowRoutes extends Backbone.Router
	routes:
		'registrants': 'registrants'
	
	registrants: ->
		app.registrants.reset()
		app.registrants.fetch(add: true)
