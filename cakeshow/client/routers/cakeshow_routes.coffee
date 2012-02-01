class exports.CakeshowRoutes extends Backbone.Router
	routes:
		'': 'index'
		'registrants': 'registrants'
	
	index: ->
		app.registrants.reset()
	
	registrants: ->
		app.registrants.fetch(add: true)
