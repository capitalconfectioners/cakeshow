url = require('url')
Sequelize = require('sequelize')
async = require('async')
fs = require('fs')
path = require('path')
child_process = require('child_process')

data_types = require('../shared/data_types')

report_dir = 'public'

exports.register = (app, cakeshowDB) ->
  middleware = new exports.DatabaseMiddleware(cakeshowDB)
  
  app.get('/toc', middleware.shows, toc)
  
  app.get('/registrants', addLinksTo(middleware.allRegistrants), registrants)
  
  app.get('/shows/:year/signups', addLinksTo(middleware.signups), signups)
  app.get('/shows/:year/signups/print', middleware.allEntries, printSignups)
  app.get('/shows/:year/signups/all', middleware.entryTable, allSignups)

  app.get('/signups', addLinksTo(middleware.signups), signups)
  app.get('/signups/:signupID', middleware.singleSignup, singleSignup)
  app.get('/signups/:signupID/print', middleware.signupWithEntries, printSingleSignup)
  
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
  result = {
    signup: signup.Signup.values
    registrant: sanitizeRegistrant(signup.Registrant)
  }

  if signup.Entries?
    result.entries = []
    for entry in signup.Entries
      result.entries.push( entry.values )

  return result

signupsToJSON = (signups) ->
  result = []
  for signup in signups
    result.push(signupToJSON(signup))
  return result

mapSignupTypes = (signup) ->
  year = signup.Signup.year

  signup.Signup.class = data_types.divisionNames[signup.Signup.class]

  if signup.Entries?
    for entry in signup.Entries
      entry.category = data_types.entryNames[year][entry.category]

  return signup

mapAllSignupTypes = (signups) ->
  for signup in signups
    mapSignupTypes(signup)

  return signups

reportFilenames = ->
  timestamp = '' + new Date().getTime()
  root_dir = path.normalize(path.join(__dirname, '..'))
  base_dir = path.join(root_dir, report_dir)
  base_file = 'entries_' + timestamp

  return [
    path.join(root_dir, 'form_generator', 'form_generator.py')
    path.join(base_dir, base_file + '.json')
    path.join(base_dir, base_file + '.pdf')
    base_file + '.pdf'
  ]

runPDFGenerator = (entry_data, callback) ->
  year = entry_data[0].signup.year

  [script, entries, report, generatedUrl] = reportFilenames()

  divisionals = (value for key, value of data_types.entryNames[year] when key.indexOf('style') == 0)
  tastings = (value for key, value of data_types.entryNames[year] when key.indexOf('special') == 0)

  data =
    metadata:
      divisionals: divisionals
      tastings: tastings
    entries: entry_data

  json = JSON.stringify(data, null, 2)

  fs.writeFile(entries, json, (err) ->
    if err
      callback(err)
    else
      child_process.exec("python #{script} #{entries} #{report}", (err, stdout, stderr) ->
        if err
          callback(err)
        else
          console.log(stdout)
          console.log(stderr)
          callback(null, '/' + generatedUrl)
      )
  )

singleSignup = (request, response, next) ->
  request.jsonResults = signupToJSON(request.signup)
  
  next()

printSingleSignup = (request, response, next) ->
  runPDFGenerator([signupToJSON(mapSignupTypes(request.signup))], (err, url) ->
    if err
      return next(new Error(err))
    response.send(url, 200)
  )

signups = (request, response, next) ->
  request.jsonResults = signupsToJSON(request.signups)
  next()

putSignup = (request, response, next) ->
  request.signup.Signup.updateAttributes(request.body)
  .success( ->
    response.json(request.signup.Signup.values)
  )
  .error( (error) ->
    return next(new Error("Could not save signup #{request.signup.id} with values #{request.body}: " + error))
  )

printSignups = (request, response, next) ->
  runPDFGenerator(signupsToJSON(mapAllSignupTypes(request.signups)), (err, url) ->
    if err
      return next(new Error(err))
    response.send(url, 200)
  )

allSignups = (request, response, next) ->
  request.jsonResults = []

  for entry in request.entries
    request.jsonResults.push(
      entry: entry.Entry.values
      signup: entry.Signup.values
      registrant: sanitizeRegistrant(entry.Registrant)
    )

  next()

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
    return next(new Error("Could not save entry #{request.entry.id} with values #{request.body}: " + error))
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
      return next(new Error("Could not select show list: " + error))
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
        return next(new Error('Could not load registrants: ' + error))
      )
    )
    .error( (error) ->
      return next(new Error('Could not count registrants: ' + error))
    )
  
  singleSignup: (request, response, next) =>
    id = parseInt(request.param('signupID'), 10)
    this.cakeshowDB.Signup.joinTo( this.cakeshowDB.Registrant, where: id )
    .success( (signup) ->
      request.signup = signup[0]
      next()
    )
    .error( (error) ->
      return next(new Error("Could not load signup #{id}: " + error))
    )

  signupWithEntries: (request, response, next) =>
    id = parseInt(request.param('signupID'), 10)
    this.cakeshowDB.Signup.joinTo( this.cakeshowDB.Registrant, where: id )
    .success( (signup) =>
      request.signup = signup[0]
      console.log(request.signup.Signup.id)
      this.cakeshowDB.Entry.findAll( where: SignupID: request.signup.Signup.id )
      .success( (entries) ->
        request.signup.Entries = entries
        next()
      )
      .error( (err) ->
        return next(new Error("Could not load entries for signup #{request.signup.id}: " + err))
      )
    )
    .error( (error) ->
      return next(new Error("Could not load signup #{id}: " + error))
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
        return next(new Error('Could not load signups: ' + error))
      )
    )
    .error( (error) ->
      return next(new Error('Could not count signups: ' + error))
    )
  
  postSignup: (request, response, next) =>
    registrantSignup = request.body
    
    if registrantSignup.signup.year? and request.param('year')? and 
    registrantSignup.signup.year != request.param('year')
      return next(new Error('Years do not match'))
    
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
        return next(new Error('Could not link signup to registrant: ' + error))
      )
    )
    .error( (error) ->
      return next(new Error('Could not create registrant and signup: ' + error))
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
      return next(new Error("Could not load entries for signup #{id}: " + error))
    )

  allEntries: (request, response, next) =>
    requestedYear = request.param('year')
    
    if requestedYear?
      filter = 
        year: requestedYear
    else
      filter = {}
    
    this.cakeshowDB.Signup.joinTo( this.cakeshowDB.Registrant, 
      where: filter
      order: 'lastname ASC, firstname ASC'
    )
    .success( (signups) =>
      async.map(signups, (signup, done) =>
        this.cakeshowDB.Entry.findAll( where: SignupID: signup.Signup.id )
        .success( (entries) ->
          signup.Entries = entries
          done(null, signup)
        )
        .error( (err) ->
          done(err)
        )
      , (err, signups) ->
        if err
          return next(new Error('Could not load entries: ' + err))
        request.signups = signups
        next()
      )
    )
    .error( (error) ->
      return next(new Error('Could not load signups: ' + error))
    )

  entryTable: (request, response, next) =>
    requestedYear = request.param('year')
    
    if requestedYear?
      filter = 
        year: requestedYear
    else
      filter = {}
    
    this.cakeshowDB.Entry.joinTo( [this.cakeshowDB.Signup,
                                   this.cakeshowDB.Registrant],
      where: filter
    )
    .success( (entries) ->
      request.entries = entries
      next()
    )
    .error( (error) ->
      next(new Error(error))
    )    

  entry: (request, response, next) =>
    id = parseInt(request.param('id'), 10)
    this.cakeshowDB.Entry.find(id)
    .success( (entry) ->
      request.entry = entry
      next()
    )
    .error( (error) ->
      return next(new Error("Could not find entry with id #{id}: " + error))
    )
  
  postEntry: (request, response, next) =>
    entryAttributes = request.body
    entryAttributes.year = request.signup.Signup.year
    
    entry = this.cakeshowDB.Entry.build(entryAttributes)
    
    entry.save()
    .success( ->
      request.signup.Signup.addEntry(entry)
      .success( ->
        response.json(entry.values)
      )
      .error( (error) ->
        return next(new Error("Could not add entry to signup: " + error))
      )
    )
    .error( (error) ->
      return next(new Error("Could not create new entry: " + error))
    )
    
