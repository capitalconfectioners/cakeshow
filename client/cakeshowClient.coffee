registrantModels = require('models/registrant_models')
signupModels = require('models/signup_models')
tocModels = require('models/toc_model')

registrantViews = require('views/registrant_views')
signupViews = require('views/signup_views')
tocViews = require('views/toc_view')

routers = require('routers/cakeshow_routes')

exports.Cakeshow = class Cakeshow
  views: {}
  routers: {}
  collections: {}
  
  initialize: (initialState) =>
    {route, link, data} = initialState
    
    route = '/registrants' if route == '/'
  
    this.registrants = new registrantModels.RegistrantList()
    this.registrantsView = new registrantViews.RegistrantListView({collection: this.registrants})
    
    this.registrantSignups = new signupModels.RegistrantSignupList()
    this.registrantSignupsView = new signupViews.RegistrantSignupListView(collection: this.registrantSignups)

    $(document).on('click', 'a', (event) =>
      target = $(event.currentTarget).attr('href')

      if target?
        this.router.navigate(target, trigger: true)
        return false
    )
    
    this.toc = new tocModels.TOC()
    this.tocView = new tocViews.TOCView(
      el: '#toc'
      model: this.toc
    )
    
    this.toc.fetch()
    this.tocView.render()
    
    this.router = new routers.CakeshowRoutes()
    Backbone.history.start(pushState: true, silent: true);
    
    this.router.queueData(link, data)
    
    # router.navigate won't trigger the route, because the current Window URL will
    # always match the URL that was passed in
    Backbone.history.loadUrl(route)
    
