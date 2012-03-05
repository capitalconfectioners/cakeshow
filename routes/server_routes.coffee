url = require('url')
Sequelize = require('sequelize')

exports.register = (app, cakeshowDB) ->
  middleware = new exports.DatabaseMiddleware(cakeshowDB)
  
  app.get('/toc', middleware.shows, toc)
  
  app.get('/registrants', addLinksTo(middleware.allRegistrants), registrants)
  
  app.get('/shows/:year/signups', addLinksTo(middleware.signups), signups)  
  app.get('/signups', addLinksTo(middleware.signups), signups)
  
  app.get('/signups/:signupID', middleware.singleSignup, singleSignup)
  
  app.put('/shows/:year/signups/:signupId', middleware.singleSignup, putSignup)
  app.put('/signups/:signupID', middleware.singleSignup, putSignup)
  
  app.post('/shows/:year/signups', middleware.postSignup)
  app.post('/signups', middleware.postSignup)
  
  app.get('/signups/:signupID/entries', middleware.entriesForSignup, entries)
  app.put('/signups/:signupID/entries/:id', middleware.entry, putEntry)
  app.post('/signups/:signupID/entries', middleware.singleSignup, middleware.postEntry)
  
  app.get('*', jsonResponse)
  app.get('*', htmlResponse)

jsonResponse = (request, response, next) ->
  if request.accepts('json')
    response.json(request.jsonResults)
  else
    next()

htmlResponse = (request, response, next) ->
  response.render('index', 
    title: 'Cakeshow'
    initialState: JSON.stringify(
      route: request.url
      link: response.header('Link')
      data: request.jsonResults
    )
  )

addLinks = (request, response, next) ->
  if request.next_page?
    nextUrl = url.parse(request.originalUrl, true)
    
    if nextUrl.query?
      nextUrl.query.page = request.next_page
    else
      nextUrl.query = {page: request.next_page}
    delete nextUrl.search
    
    link = "<#{url.format(nextUrl)}>; rel=\"next\""
  
  if request.prev_page?
    prevUrl = url.parse(request.originalUrl, true)
    
    if prevUrl.query?
      prevUrl.query.page = request.prev_page
    else
      prevUrl.query = {page: request.prev_page}
    
    delete prevUrl.search
    
    if link?
      link += ", "
    else
      link = ""
    
    link += "<#{url.format(prevUrl)}>; rel=\"prev\""
  
  if link?
    response.header('Link', link)
  
  next()

addLinksTo = (route) ->
  return [route, addLinks]

toc = (request, response, next) ->
  toc = 
    Registrants: '/registrants'
    Shows: {}
  
  for show in request.shows
    toc.Shows[show] = '/shows/' + show + '/signups'
  
  response.json(toc)

sanitizeRegistrant = (registrant) ->
  rawRegistrant = {}
  rawRegistrant[key] = value for key, value of registrant.values when key != 'password'
  return rawRegistrant  

registrants = (request, response, next) -> 
  request.jsonResults = []
  for registrant in request.registrants
    request.jsonResults.push(sanitizeRegistrant(registrant))

  next()

signupToJSON = (signup) ->
  return {
    signup: signup.Signup.values
    registrant: sanitizeRegistrant(signup.Registrant)
  }

singleSignup = (request, response, next) ->
  request.jsonResults = signupToJSON(request.signup)
  
  next()

signups = (request, response, next) ->
  request.jsonResults = []
  for signup in request.signups
    request.jsonResults.push(signupToJSON(signup))
  
  next()

putSignup = (request, response, next) ->
  request.signup.Signup.updateAttributes(request.body)
  .success( ->
    response.json(request.signup.Signup.values)
  )
  .error( (error) ->
    next(new Error("Could not save signup #{request.signup.id} with values #{request.body}: " + error))
  )

entries = (request, response, next) ->
  request.jsonResults = []
  for entry in request.entries
    request.jsonResults.push( entry.values )
  
  response.json(request.jsonResults)

putEntry = (request, response, next) ->
  request.entry.updateAttributes(request.body)
  .success( ->
    response.json(request.entry.values)
  )
  .error( (error) ->
    next(new Error("Could not save entry #{request.entry.id} with values #{request.body}: " + error))
  )

exports.DatabaseMiddleware = class DatabaseMiddleware
  constructor: (cakeshowDB) ->
    this.cakeshowDB = cakeshowDB
  
  shows: (request, response, next) =>
    distinct = 
      build: (values) ->
        return values.year
      
    this.cakeshowDB.cakeshowDB.getQueryInterface().select(distinct, this.cakeshowDB.Signup.tableName, 
      attributes: [['distinct year', 'year']]
    )
    .success( (years) ->
      request.shows = years
      next()
    )
    .error( (error) ->
      next(new Error("Could not select show list: " + error))
    )
  
  attachPagination: (request, count) ->
    result = {}
    
    result.page = parseInt(request.param('page','1'), 10)
    result.limit = parseInt(request.param('page_size','25'), 10)
    
    result.offset = (result.page-1)*result.limit
    
    request.total_results = count
      
    if result.page > 1 
      request.prev_page = result.page-1
    
    if result.offset + result.limit < count
      request.next_page = result.page+1
    
    return result
  
  allRegistrants: (request, response, next) =>
    
    this.cakeshowDB.Registrant.count().success( (count) =>
      {page, limit, offset} = this.attachPagination(request, count)
      
      this.cakeshowDB.Registrant.findAll(
        offset:offset
        limit:limit
        order: 'lastname ASC, firstname ASC')
      .success( (registrants) ->
        request.registrants = registrants
        next()
      )
      .error( (error) ->
        next(new Error('Could not load registrants: ' + error))
      )
    )
    .error( (error) ->
      next(new Error('Could not count registrants: ' + error))
    )
  
  singleSignup: (request, response, next) =>
    id = parseInt(request.param('signupID'), 10)
    this.cakeshowDB.Signup.joinTo( this.cakeshowDB.Registrant, where: id )
    .success( (signup) ->
      request.signup = signup[0]
      next()
    )
    .error( (error) ->
      next(new Error("Could not load signup #{id}: " + error))
    )
  
  signups: (request, response, next) =>
    requestedYear = request.param('year')
    
    if requestedYear?
      filter = 
        year: requestedYear
    else
      filter = {}
    
    search = request.param('search')
    if search?
      filters = []
      
      if filter.year?
        yearFilter = this.cakeshowDB.Signup.quoted('year') + " = '#{filter.year}'"
        filters.push(yearFilter)
      
      firstnameFilter = this.cakeshowDB.Registrant.quoted('firstname') + " LIKE '%#{search}%'"
      lastnameFilter = this.cakeshowDB.Registrant.quoted('lastname') + " LIKE '%#{search}%'"
      
      nameFilter = [firstnameFilter, lastnameFilter].join(" OR ")
      filters.push('(' + nameFilter + ')')
      
      filter = filters.join(" AND ")
    
    this.cakeshowDB.Signup.countJoined( this.cakeshowDB.Registrant, where: filter )
    .success( (count) =>
      {page, limit, offset} = this.attachPagination(request, count)
      
      this.cakeshowDB.Signup.joinTo( this.cakeshowDB.Registrant, 
        where: filter
        offset:offset
        limit:limit
        order: 'lastname ASC, firstname ASC'
      )
      .success( (signups) ->
        request.signups = signups
        next()
      )
      .error( (error) ->
        next(new Error('Could not load signups: ' + error))
      )
    )
    .error( (error) ->
      next(new Error('Could not count signups: ' + error))
    )
  
  postSignup: (request, response, next) =>
    registrantSignup = request.body
    
    if registrantSignup.signup.year? and request.param('year')? and 
    registrantSignup.signup.year != request.param('year')
      next(new Error('Years do not match'))
    
    registrant = this.cakeshowDB.Registrant.build(registrantSignup.registrant)
    signup = this.cakeshowDB.Signup.build(registrantSignup.signup)
    
    chain = new Sequelize.Utils.QueryChainer()
    
    chain.add(registrant.save())
    chain.add(signup.save())
    chain.run()
    .success( ->
      registrant.addSignup(signup)
      .success( ->
        response.header('Location', '/signups/' + signup.id)
        response.json(signupToJSON( Registrant: registrant, Signup: signup ))
      )
      .error( (error) ->
        next(new Error('Could not link signup to registrant: ' + error))
      )
    )
    .error( (error) ->
      next(new Error('Could not create registrant and signup: ' + error))
    ) 
  
  entriesForSignup: (request, response, next) =>
    signupID = request.param('signupID')
    this.cakeshowDB.Entry.findAll( where: SignupID: signupID )
    .success( (entries) ->
      for entry in entries
        entry.didBring = if entry.didBring == 0 then false else true
        entry.styleChange = if entry.styleChange == 0 then false else true
      request.entries = entries
      next()
    )
    .error( (error) ->
      next(new Error("Could not load entries for signup #{id}: " + error))
    )
  
  entry: (request, response, next) =>
    id = parseInt(request.param('id'), 10)
    this.cakeshowDB.Entry.find(id)
    .success( (entry) ->
      request.entry = entry
      next()
    )
    .error( (error) ->
      next(new Error("Could not find entry with id #{id}: " + error))
    )
  
  postEntry: (request, response, next) =>
    entryAttributes = request.body
    entryAttributes.year = request.signup.Signup.year
    
    entry = this.cakeshowDB.Entry.build(entryAttributes)
    
    entry.save()
    .success( ->
      request.signup.Signup.addEntrie(entry)
      .success( ->
        response.json(entry.values)
      )
      .error( (error) ->
        next(new Error("Could not add entry to signup: " + error))
      )
    )
    .error( (error) ->
      next(new Error("Could not create new entry: " + error))
    )
    
