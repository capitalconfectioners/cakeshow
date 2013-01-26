{PagedCollection} = require('./paged_collection')

RegistrantModels = require('./registrant_models')

cakeshowTypes = require('../data_types')

exports.Entry = class Entry extends Backbone.Model
  urlRoot: '/entries'
  
  getCategories: =>
    return (value for key, value of cakeshowTypes.entryNames[this.get('year')])
  
  categoryName: =>
    return cakeshowTypes.entryNames[this.get('year')][this.get('category')]
  
  setCategoryName: (categoryName) =>
    category = key for key, value of cakeshowTypes.entryNames[this.get('year')] when value == categoryName
    this.set('category', category)
    
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
  
  divisionName: =>
    return cakeshowTypes.divisionNames[this.get('class')]
  
  setDivisionName: (divisionName) =>
    division = key for key, value of cakeshowTypes.divisionNames when value == divisionName
    this.set('class', division)
  
  getDivisions: ->
    return (value for key, value of cakeshowTypes.divisionNames)

exports.RegistrantSignup = class RegistrantSignup extends Backbone.Model
  urlRoot: '/signups'
  
  initialize: =>
    this.signup = this.get('signup')
    this.registrant = this.get('registrant')
  
  parse: (response, xhr) =>
    this.signup = new exports.Signup(response.signup)
    this.registrant = new RegistrantModels.Registrant(response.registrant)
    
    return {
      signup: this.signup
      registrant: this.registrant
    }
  
  toJSON: =>
    return {
      signup: this.get('signup').toJSON()
      registrant: this.get('registrant').toJSON()
    }
  
  validate: =>
    return null
  
exports.RegistrantSignupList = class RegistrantSignupList extends PagedCollection
  model: RegistrantSignup
  unfilteredUrl: '/signups'
  showUrl: '/shows'
  
  initialize: () ->
    this.clearYear()
  
  setYear: (year) ->
    this.year = year
    this.baseUrl = this.showUrl + '/' + year + '/signups'
    this.url = this.baseUrl
  
  clearYear: =>
    this.year = null
    this.baseUrl = this.unfilteredUrl
    this.url = this.baseUrl
  
  newSignup: =>
    signup = new exports.Signup()
    registrant = new RegistrantModels.Registrant()
    
    if this.year?
      signup.set('year', this.year)
    
    return new RegistrantSignup(
      signup: signup
      registrant: registrant
    )
  
  search: (phrase, callback, error) =>
    $.ajax(this.baseUrl + '?search=' + phrase,
      success: (data, textStatus, xhr) ->
        callback(data)
      error: (xhr, textStatus, errorThrown) ->
        if error?
          error(textStatus, errorThrown)
    )

  printUrl: (success, error) ->
    $.get(this.url + '/print')
      .done((data) ->
        success(data)
      ).fail((data) ->
        error?(data)
      )
    