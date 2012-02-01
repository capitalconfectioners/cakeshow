exports.Registrant = class Registrant extends Backbone.Model
	

exports.RegistrantList = class RegistrantList extends Backbone.Collection
	model: Registrant
	url: '/registrants'

