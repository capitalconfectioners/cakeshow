{PagedListView} = require('./paged_views')

registrantTemplate = require('./templates/registrant')
registrantListTemplate = require('./templates/registrant_list')

exports.RegistrantView = class RegistrantView extends Backbone.View
	className: 'registrant'
	
	initialize: ->
		this.model.bind('all', this.render)
		this.model.view = this
	
	render: =>
		json = this.model.toJSON()
		this.$el.html(registrantTemplate.render(json))
		return this

exports.RegistrantListView = class RegistrantListView extends PagedListView
	el: '#content'
	
	initialize: ->
		this.registerPagination('registrants')
		this.collection.bind('reset', this.render)
		this.collection.bind('add', this.add)
		this.collection.view = this
	
	add: (registrant) =>
		view = new RegistrantView( {tagName: 'li', model: registrant} )
		this.$el.find('#registrants').append(view.render().el)
		
	render: =>
		this.$el.html(registrantListTemplate.render())
		
		this.add(registrant) for registrant in this.collection.models
		
		super()
		return this
