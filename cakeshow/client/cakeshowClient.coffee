registrantModels = require('models/registrant_models')
signupModels = require('models/signup_models')

registrantViews = require('views/registrant_views')
signupViews = require('views/signup_views')

routers = require('routers/cakeshow_routes')

exports.Cakeshow = class Cakeshow
	views: {}
	routers: {}
	collections: {}
	
	initialize: (initialState) =>
		{route, link, data} = initialState
		
		route = '/registrants' if route == '/'
	
		this.registrants = new registrantModels.RegistrantList()
		this.registrantsView = new registrantViews.RegistrantListView({collection: this.registrants})
		
		this.registrantSignups = new signupModels.RegistrantSignupList()
		this.registrantSignupsView = new signupViews.RegistrantSignupListView(collection: this.registrantSignups)
	
		this.router = new routers.CakeshowRoutes()
		Backbone.history.start(pushState: true, silent: true);
		
		this.router.queueData(link, data)
		
		# router.navigate won't trigger the route, because the current Window URL will
		# always match the URL that was passed in
		Backbone.history.loadUrl(route)
		
