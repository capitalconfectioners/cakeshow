exports.RegistrantView = class RegistrantView extends Backbone.View
	tagName: 'li'
	
	initialize: ->
		this.model.bind('all', this.render)
		this.model.view = this
	
	render: =>
		json = this.model.toJSON()
		this.$(this.el).html(json.firstname + ' ' + json.lastname)
		return this

exports.RegistrantListView = class RegistrantListView extends Backbone.View
	el: '#registrant_list'
	
	initialize: ->
		this.collection.bind('reset', this.render)
		this.collection.bind('add', this.add)
		this.collection.view = this
	
	add: (registrant) =>
		view = new RegistrantView( {model: registrant} )
		$(this.el).find('#registrants').append(view.render().el)
		
	# Called only once, when a route is fetched
	render: =>
		this.$(this.el).html('<ul id="registrants"></ul>')
		return this