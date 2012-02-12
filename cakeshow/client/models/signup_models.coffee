{PagedCollection} = require('./paged_collection')

RegistrantModels = require('./registrant_models')

exports.Entry = class Entry extends Backbone.Model
  urlRoot: '/entries'
    
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
  urlRoot: '/signups'
  
  parse: (response, xhr) =>
    this.signup = new exports.Signup(response.signup)
    this.registrant = new RegistrantModels.Registrant(response.registrant)
    
    return {
      signup: this.signup
      registrant: this.registrant
    }
  
exports.RegistrantSignupList = class RegistrantSignupList extends PagedCollection
  model: RegistrantSignup
  unfilteredUrl: '/shows'
  
  initialize: () ->
    this.baseUrl = this.unfilteredUrl 
    this.url = this.baseUrl
  
  setYear: (year) ->
    this.baseUrl = this.unfilteredUrl + '/' + year + '/signups'
    this.url = this.baseUrl
  
  search: (phrase, callback, error) =>
    $.ajax(this.baseUrl + '?search=' + phrase,
      success: (data, textStatus, xhr) ->
        callback(data)
      error: (xhr, textStatus, errorThrown) ->
        if error?
          error(textStatus, errorThrown)
    )
    