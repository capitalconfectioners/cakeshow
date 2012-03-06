{PagedCollection} = require('./paged_collection')

exports.Registrant = class Registrant extends Backbone.Model
  fullName: =>
    return this.get('firstname') + ' ' + this.get('lastname')

exports.RegistrantList = class RegistrantList extends PagedCollection
	model: Registrant
	baseUrl: '/registrants'
	
	initialize: () =>
		this.url = this.baseUrl
