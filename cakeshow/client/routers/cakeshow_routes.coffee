models = require('models/registrant_models')

class exports.CakeshowRoutes extends Backbone.Router
  routes:
    'registrants': 'registrants'
    'registrants?:querystring': 'registrants'
    
    'signups/:year': 'signups'
    'signups/:year?:querystring': 'signups'
    
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
  
  registrants: (querystring)->
    app.registrants.setQueryString(querystring)
    this.fetchData(app.registrants)
  
  signups: (year, querystring) ->
    app.registrantSignups.setYear(year)
    app.registrantSignups.setQueryString(querystring)
    this.fetchData(app.registrantSignups)
  
  queueData: (link, data) ->
    this.dataQueue = 
      link: link
      data: data
  
  fetchData: (collection) ->
    if this.dataQueue?
      collection.fillData(this.dataQueue.link, this.dataQueue.data)
      this.dataQueue = null
    else
      collection.fetch()
    