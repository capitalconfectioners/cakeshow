{PagedListView} = require('./paged_views')

RegistrantViews = require('./registrant_views')

signupTemplate = require('./templates/signup')
registrantSignupTemplate = require('./templates/registrant_signup')
registrantSignupListTemplate = require('./templates/registrant_signup_list')

exports.SignupView = class SignupView extends Backbone.View
  className: 'signup'
  
  render: =>
    this.$el.html(signupTemplate.render(this.model.toJSON()))
    return this

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
    