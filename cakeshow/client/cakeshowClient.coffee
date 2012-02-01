models = require('models/registrant_models')
views = require('views/registrant_views')
routers = require('routers/cakeshow_routes')

exports.Cakeshow = class Cakeshow
	views: {}
	routers: {}
	collections: {}
	
	initialize: (startRoute = "/registrants") =>
		this.registrants = new models.RegistrantList()
		this.registrantsView = new views.RegistrantListView({collection: this.registrants})
		
		this.router = new routers.CakeshowRoutes()
		Backbone.history.start({pushState: true});
		
		this.router.navigate(startRoute, true)
