exports.Registrant = class Registrant extends Backbone.Model
	

exports.RegistrantList = class RegistrantList extends Backbone.Collection
	model: Registrant
	baseUrl: '/registrants'
	
	initialize: () =>
		this.url = this.baseUrl
	
	# Idea to do URL overriding stolen from https://gist.github.com/838460
	# but parsing the next/prev from the HTTP Response headers, which are raw
	# links, instead of page indexes
	parse: (response, xhr) =>
		nextCheck = /<([^>]*)>; rel="next"/
		prevCheck = /<([^>]*)>; rel="prev"/
		
		links = xhr.getResponseHeader('Link')
		
		nextMatch = nextCheck.exec(links)
		if nextMatch?
			this.next = nextMatch[1]
		else
			this.next = null
			
		prevMatch = prevCheck.exec(links)
		if prevMatch?
			this.prev = prevMatch[1]
		else
			this.prev = null
		
		this.trigger('parsed', this, {})
		
		return response
	
	setUrl: (url) =>
		if url?
			this.url = this.baseUrl + '?' + url
		else
			this.url = this.baseUrl
	
	nextPage: =>
		app.router.navigate(this.next, trigger: true)
	
	prevPage: =>
		app.router.navigate(this.prev, trigger: true)
