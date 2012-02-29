signupModels = require('models/signup_models')
signupViews = require('views/signup_views')

class exports.CakeshowRoutes extends Backbone.Router
  routes:
    'registrants': 'registrants'
    'registrants?:querystring': 'registrants'
    
    'shows/:year/signups': 'signups'
    'shows/:year/signups?:querystring': 'signups'
    
    'signups/:id': 'singleSignup'
    
  namedParam: /:\w+/g;
  splatParam: /\*\w+/g;
  escapeRegExp: /[-[\]{}()+?.,\\^$|#\s]/g;
  
  route: (route, name, callback) ->
    if (!_.isRegExp(route)) 
      route = this._routeToQueryRegExp(route)
    
    super(route, name, callback)
  
  _routeToQueryRegExp: (route) ->
    route = route.replace(this.escapeRegExp, '\\$&')
      .replace(this.namedParam, '([^\/?]+)')
      .replace(this.splatParam, '(.*?)')
    return new RegExp('^' + route + '$')
  
  registrants: (querystring) ->
    this.currentView = app.registrantsView
    this.currentModel = app.registrants
    
    app.registrants.setQueryString(querystring)
    this.fetchData(app.registrants)
  
  signups: (year, querystring) ->
    this.currentView = app.registrantSignupsView
    this.currentModel = app.registrantSignups
    
    this.setSearchToSignups()
    
    app.registrantSignups.setYear(year)
    app.registrantSignups.setQueryString(querystring)
    this.fetchData(app.registrantSignups)
  
  singleSignup: (id) ->
    console.log('single signup: ' + id)
    this.currentModel = new signupModels.RegistrantSignup(id: id)
    this.currentView = new signupViews.RegistrantSignupView(
      el: '#content'
      model: this.currentModel
    )
    
    this.setSearchToSignups()
    
    this.fetchData(this.currentModel)
  
  setSearchToSignups: () ->
    if this.searchView?.type == 'signups'
      return
    
    this.searchView = new signupViews.SignupSearch(
      collection: app.registrantSignups
    )
    this.searchView.render()
  
  queueData: (link, data) ->
    this.dataQueue = 
      link: link
      data: data
  
  fetchData: (model) ->
    if this.dataQueue?
      if model.fillData?
        model.fillData(this.dataQueue.link, this.dataQueue.data)
      else
        model.set(model.parse(this.dataQueue.data))
      this.dataQueue = null
    else
      model.fetch()
    