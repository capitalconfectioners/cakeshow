{PagedListView} = require('./paged_views')

RegistrantViews = require('./registrant_views')

entryTemplate = require('./templates/entry')
entryListTemplate = require('./templates/entry_list')

signupTemplate = require('./templates/signup')
registrantSignupTemplate = require('./templates/registrant_signup')
registrantSignupListTemplate = require('./templates/registrant_signup_list')

exports.EntryView = class EntryView extends Backbone.View
  tagName: 'tr'
  className: 'entry'
  
  render: =>
    this.$el.html(entryTemplate.render(this.model.toJSON()))
    return this

exports.EntryListView = class EntryListView extends Backbone.View
  tagName: 'table'
  className: 'entry-list'
  
  initialize: ->
    this.collection.bind('reset', this.render)
    this.collection.bind('add', this.add)
    this.collection.view = this
  
  add: (entry) =>
    view = new EntryView(model: entry)
    this.$el.append(view.render().el)
    
  render: =>
    this.$el.html(entryListTemplate.render())
    this.add(entry) for entry in this.collection.models
    
    return this

exports.SignupView = class SignupView extends Backbone.View
  className: 'signup'
  
  render: =>
    this.$el.html(signupTemplate.render(this.model.toJSON()))
    this.$el.find('.accordion').accordion(
      collapsible: true
      active: false
      autoHeight: false
      changestart: this.toggleEvents
    )
    return this
  
  toggleEvents: =>
    unless this.entriesView?
      this.entriesView = new EntryListView(collection: this.model.getEntries())
      this.entriesView.collection.fetch()
      this.$el.find('.entries').append(this.entriesView.render().el)
      console.log(this.$el.find('.accordion'))

exports.RegistrantSignupView = class RegistrantSignupView extends Backbone.View
  className: 'registrantSignup'
  
  render: =>
    this.$el.html(registrantSignupTemplate.render())
    signupView = new SignupView(tagName: 'div', model: this.model.signup)
    registrantView = new RegistrantViews.RegistrantView(tagName: 'div', model: this.model.registrant)
    
    this.$el.find('.signup').append(signupView.render().el)
    this.$el.find('.registrant').append(registrantView.render().el)
    
    return this
  
exports.RegistrantSignupListView = class RegistrantSignupListView extends PagedListView
  el: '#content'
  
  initialize: =>
    this.register('registrant-signups')
    this.collection.bind('reset', this.render)
    this.collection.bind('add', this.add)
    this.collection.view = this
  
  add: (registrantSignup) =>
    view = new RegistrantSignupView( {tagName: 'li', model: registrantSignup} )
    this.$el.find('#registrant-signups').append(view.render().el)
    
  render: =>
    this.$el.html(registrantSignupListTemplate.render())
    
    this.add(registrantSignup) for registrantSignup in this.collection.models
    
    super()
    return this
    