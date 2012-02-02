models = require('models/registrant_models')
views = require('views/registrant_views')
routers = require('routers/cakeshow_routes')

exports.Cakeshow = class Cakeshow
	views: {}
	routers: {}
	collections: {}
	
	initialize: (initialState) =>
		{route, link, data} = initialState
		
		route = '/registrants' if route == '/'
	
		this.registrants = new models.RegistrantList()
		this.registrantsView = new views.RegistrantListView({collection: this.registrants})
	
		this.router = new routers.CakeshowRoutes()
		Backbone.history.start(pushState: true, silent: true);
		
		this.registrants.fillData(link, data)
		
		this.router.navigate(route)
		
