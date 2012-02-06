url = require('url')

exports.register = (app, cakeshowDB) ->
  middleware = new exports.DatabaseMiddleware(cakeshowDB)

  app.get('*', log)
  app.get('/registrants', addLinksTo(middleware.allRegistrants), registrants)
  app.get('/signups/:year', addLinksTo(middleware.signups), signups)
  app.get('*', jsonResponse)
  app.get('*', htmlResponse)

log = (request, response, next) ->
  console.log('Request at ' + request.originalUrl)
  next()

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

sanitizeRegistrant = (registrant) ->
  rawRegistrant = {}
  rawRegistrant[key] = value for key, value of registrant.values when key != 'password'
  return rawRegistrant  

registrants = (request, response, next) -> 
  request.jsonResults = []
  for registrant in request.registrants
    request.jsonResults.push(sanitizeRegistrant(registrant))

  next()

signups = (request, response, next) ->
  request.jsonResults = []
  for signup in request.signups
    request.jsonResults.push(
      signup: signup.Signup.values
      registrant: sanitizeRegistrant(signup.Registrant)
    )
  
  next()

exports.DatabaseMiddleware = class DatabaseMiddleware
  constructor: (cakeshowDB) ->
    this.cakeshowDB = cakeshowDB
  
  attachPagination: (request, count) ->
    result = {}
    
    result.page = parseInt(request.param('page','1'), 10)
    result.limit = parseInt(request.param('page_size','25'), 10)
    
    result.offset = (result.page-1)*result.limit
    
    console.log(result)
    console.log(count)
    
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
  
  signups: (request, response, next) =>
    
    this.cakeshowDB.Signup.count( where: year: request.param('year','2012') )
    .success( (count) =>
      {page, limit, offset} = this.attachPagination(request, count)
      
      this.cakeshowDB.Signup.joinTo( this.cakeshowDB.Registrant, 
        where: year: request.param('year','2012')
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
