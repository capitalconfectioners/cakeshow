exports.register = (app, cakeshowDB) ->
  middleware = new exports.DatabaseMiddleware(cakeshowDB)

  app.get('/registrants', addLinksTo(middleware.allRegistrants), exports.registrants)
  app.get('/signups/:year', addLinksTo(middleware.signups), exports.signups)
  app.get('*', exports.index)

exports.index = (request, response, next) ->
  response.render('index', 
    title: 'Cakeshow'
    initialState: JSON.stringify(
      route: request.url
      link: response.header('Link')
      data: request.sanitizedRegistrants
    )
  )

addLinks = (request, response, next) ->
  if request.next_page?
    link = "<#{request.route.path}?page=#{request.next_page}>; rel=\"next\""
  
  if request.prev_page?
    if link?
      link += ", "
    else
      link = ""
    
    link += "<#{request.route.path}?page=#{request.prev_page}>; rel=\"prev\""
  
  if link?
    response.header('Link', link)
  
  next()

addLinksTo = (route) ->
  return [route, addLinks]

sanitizeRegistrant = (registrant) ->
  rawRegistrant = {}
  rawRegistrant[key] = value for key, value of registrant.values when key != 'password'
  return rawRegistrant  

exports.registrants = (request, response, next) -> 
  request.sanitizedRegistrants = []
  for registrant in request.registrants
    request.sanitizedRegistrants.push(sanitizeRegistrant(registrant))

  if request.accepts('json')
    response.json(request.sanitizedRegistrants)
  else
    next()

exports.signups = (request, response, next) ->
  result = []
  for signup in request.signups
    result.push(
      signup: signup.Signup.values
      registrant: sanitizeRegistrant(signup.Registrant)
    )
  
  response.json(result)

exports.DatabaseMiddleware = class DatabaseMiddleware
  constructor: (cakeshowDB) ->
    this.cakeshowDB = cakeshowDB
  
  pages: (request) ->
    result = {}
    
    result.page = parseInt(request.param('page','1'), 10)
    result.limit = parseInt(request.param('page_size','25'), 10)
    
    result.offset = (result.page-1)*result.limit
    
    return result
  
  allRegistrants: (request, response, next) =>
    {page, limit, offset} = this.pages(request)
    
    this.cakeshowDB.Registrant.count().success( (count) =>
      request.total_registrants = count
      
      if page > 1 
        request.prev_page = page-1
      
      if offset + limit < count
        request.next_page = page+1
      
      this.cakeshowDB.Registrant.findAll(offset:offset, limit:limit, order: 'lastname ASC, firstname ASC').success( (registrants) ->
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
  
  disambiguate: (model) ->
    result = []
    for column of model.rawAttributes
      sqlSelect = "`#{model.tableName}`.`#{column}`"
      if column == 'id'
        result.push([sqlSelect, "#{model.tableName}_#{column}"])
      else
        result.push(sqlSelect)
    return result
  
  joinAttributes: (left, right) ->
    attributes = this.disambiguate(left).concat(this.disambiguate(right))
    return attributes
  
  signups: (request, response, next) =>
    #{page, limit, offset} = this.pages(request)
    
    this.cakeshowDB.Signup.joinTo( this.cakeshowDB.Registrant, 
      where: year: request.param('year','2012')
    )
    .success( (signups) ->
      request.signups = signups
      next()
    )
    .error( (error) ->
      next(new Error('Could not load signups: ' + error))
    )
