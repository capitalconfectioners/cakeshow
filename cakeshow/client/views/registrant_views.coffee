exports.RegistrantView = class RegistrantView extends Backbone.View
	tagName: 'li'
	
	initialize: ->
		this.model.bind('all', this.render)
		this.model.view = this
	
	render: =>
		json = this.model.toJSON()
		this.$el.html(json.firstname + ' ' + json.lastname)
		return this

exports.RegistrantListView = class RegistrantListView extends Backbone.View
	el: '#registrant_list'
	
	events:
		'click .next': 'next'
		'click .prev': 'prev'
	
	initialize: ->
		this.collection.bind('reset', this.render)
		this.collection.bind('add', this.add)
		this.collection.view = this
	
	add: (registrant) =>
		view = new RegistrantView( {model: registrant} )
		this.$el.find('#registrants').append(view.render().el)
		
	render: =>
		this.$el.html('<ul id="registrants"></ul><a class="prev">prev</a><a class="next">next</a>')
		
		this.add(registrant) for registrant in this.collection.models
		
		this.$el.find('.next').button(disabled: not this.collection.next?)
		this.$el.find('.prev').button(disabled: not this.collection.prev?)
		return this
	
	next: =>
		app.router.navigate(this.collection.next, trigger: true)
	
	prev: =>
		app.router.navigate(this.collection.prev, trigger: true)