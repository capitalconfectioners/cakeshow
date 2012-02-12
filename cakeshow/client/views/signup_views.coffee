{PagedListView} = require('./paged_views')

RegistrantViews = require('./registrant_views')

entryTemplate = require('./templates/entry')
entryListTemplate = require('./templates/entry_list')

signupTemplate = require('./templates/signup')
registrantSignupTemplate = require('./templates/registrant_signup')
registrantSignupListTemplate = require('./templates/registrant_signup_list')

validations = require('../validations')

exports.EntryView = class EntryView extends Backbone.View
  tagName: 'tr'
  className: 'entry'
  
  events:
    'click input.didBring': 'didBringClicked'
    'click input.styleChange': 'styleChangeClicked'
    'change select.style': 'styleChanged'
  
  render: =>
    renderParams = this.model.toJSON()
    renderParams.styles = validations.entryTypes
    this.$el.html(entryTemplate.render(renderParams))
    selectedIndex = _.indexOf(validations.entryTypes, renderParams.category)
    this.$el.find('select.style')[0].selectedIndex = selectedIndex
    return this
  
  didBringClicked: =>
    this.model.set('didBring', this.$el.find('.didBring')[0].checked)
    this.model.save()
  
  styleChangeClicked: =>
    this.model.set('styleChange', this.$el.find('.styleChange')[0].checked)
    this.model.save()
  
  styleChanged: =>
    selected = this.$el.find('select.style')[0].selectedIndex
    this.model.set('category', validations.entryTypes[selected])
    this.model.set('styleChange', true)
    this.$el.find('input.styleChange')[0].checked = true
    this.model.save()

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

exports.RegistrantSignupView = class RegistrantSignupView extends Backbone.View
  className: 'registrantSignup'
    
  initialize: =>
    this.model.bind('change', this.render)
  
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
    $('div.search-fields input').autocomplete(
      minLength: 2
      source: this.searchSuggestions
      select: this.searchSelected
    )
    this.$el.html(registrantSignupListTemplate.render())
    
    this.add(registrantSignup) for registrantSignup in this.collection.models
    
    super()
    return this
  
  searchSuggestions: (request, callback) =>
    this.collection.search(request.term, (results) ->
      for result in results
        result.value = result.registrant.firstname + " " + result.registrant.lastname
      
      callback(results)
    )
  
  searchSelected: (event, ui) =>
    app.router.navigate('/signups/' + ui.item.signup.id, trigger: true)
    