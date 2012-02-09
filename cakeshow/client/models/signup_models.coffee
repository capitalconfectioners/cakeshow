{PagedCollection} = require('./paged_collection')

RegistrantModels = require('./registrant_models')

exports.Entry = class Entry extends Backbone.Model
  
exports.EntryList = class EntryList extends Backbone.Collection
  model: Entry
  
  setParent: (signup) ->
    this.url = "#{signup.url()}/entries"

exports.Signup = class Signup extends Backbone.Model
  urlRoot: '/signups'
  
  getEntries: =>
    unless this.entries?
      this.entries = new EntryList()
      this.entries.setParent(this)
    return this.entries

exports.RegistrantSignup = class RegistrantSignup extends Backbone.Model
  parse: (response, xhr) =>
    this.signup = new exports.Signup(response.signup)
    this.registrant = new RegistrantModels.Registrant(response.registrant)
    
    return {}
  
exports.RegistrantSignupList = class RegistrantSignupList extends PagedCollection
  model: RegistrantSignup
  unfilteredUrl: '/signups'
  
  initialize: () ->
    this.baseUrl = this.unfilteredUrl 
    this.url = this.baseUrl
  
  setYear: (year) ->
    this.baseUrl = this.unfilteredUrl + '/' + year
    this.url = this.baseUrl
    