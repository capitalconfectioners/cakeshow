models = require('models/registrant_models')
views = require('views/registrant_views')
routers = require('routers/cakeshow_routes')

exports.Cakeshow = class Cakeshow
	views: {}
	routers: {}
	collections: {}
	
	initialize: (startRoute) =>
		startRoute = '/registrants' if startRoute = '/'
	
		this.initRegistrants()
	
		this.router = new routers.CakeshowRoutes()
		Backbone.history.start(pushState: true, silent: true);
		
		this.router.navigate(startRoute, trigger: true)
	
	initRegistrants: (url) =>
		this.registrants = new models.RegistrantList(url)
		this.registrantsView = new views.RegistrantListView({collection: this.registrants})
		
