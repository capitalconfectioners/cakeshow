{PagedCollection} = require('./paged_collection')

exports.Registrant = class Registrant extends Backbone.Model

exports.RegistrantList = class RegistrantList extends PagedCollection
	model: Registrant
	baseUrl: '/registrants'
	
	initialize: () =>
		this.url = this.baseUrl
