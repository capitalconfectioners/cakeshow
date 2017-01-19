url = require('url')
Sequelize = require('sequelize')
Sequelize.Utils = require('sequelize/lib/utils')
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
  app.get('/shows/:year/signups/winners', middleware.winners, getWinners)
  app.get('/shows/:year/signups/winners/report.csv', middleware.winners, getWinnersReport)
  app.post('/shows/:year/signups/winners/best/best/best', middleware.postBestOfShow, postWinner)
  app.post('/shows/:year/signups/winners/:division/best/best', middleware.postBestOfDivision, postWinner)
  app.post('/shows/:year/signups/winners/:division/:category/:place', middleware.postWinner, postWinner)

  app.get('/signups', addLinksTo(middleware.signups), signups)
  app.get('/signups/:signupID', middleware.singleSignup, singleSignup)
  app.get('/signups/:signupID/print', middleware.signupWithEntries, printSingleSignup)

  app.get('/entries/:entryID', middleware.entryWithSignup, getEntry)

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
  rawRegistrant[key] = value for key, value of registrant.get() when key != 'password' and key != 'Signups'
  return rawRegistrant

registrants = (request, response, next) ->
  request.jsonResults = []
  for registrant in request.registrants
    request.jsonResults.push(sanitizeRegistrant(registrant))

  next()

signupToJSON = (signup) ->
  result = {
    signup: signup.Signup
    registrant: sanitizeRegistrant(signup.Registrant)
  }

  if signup.Entries?
    result.entries = []
    for entry in signup.Entries
      result.entries.push( entry )

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
  showcases = (value for key, value of data_types.entryNames[year] when key.indexOf('showcase') == 0)

  data =
    metadata:
      divisionals: divisionals
      tastings: tastings
      showcases: showcases
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

getEntry = (request, response, next) ->
  response.json(
    entry: request.entry.Entry.values
    signup: request.entry.Signup.values
    registrant: sanitizeRegistrant(request.entry.Registrant)
  )

collateWinners = (winnersList, year, renderWinner) ->
  winners = {}

  for winner in winnersList
    category = winner.Entry.category
    division = if data_types.isDivisional(category, year)
      winner.Signup.class
    else if data_types.isTasting(category)
      'tasting'
    else if category in data_types.singleShowcaseTypes
      'showcase-single'
    else if category in data_types.teamShowcaseTypes
      'showcase-team'

    winners[division] ?= {}
    winners[division][category] ?= {}

    winnerView = renderWinner(winner)

    if winner.Entry.bestInDivision
      winners[division].best = winnerView

    if winner.Entry.bestInShow
      winners.best = winnerView

    winners[division][category][winner.Entry.divisionPlace] = winnerView

  return winners

getWinners = (request, response, next) ->
  winners = collateWinners(request.winners, request.param('year'), (winner) ->
    entry: winner.Entry.values
    signup: winner.Signup.values
    registrant: sanitizeRegistrant(winner.Registrant)
  )

  request.jsonResults = winners
  next()

placeName = (place) ->
  ['1st', '2nd', '3rd'][place - 1]

getDivisionWinnersReport = (year, winners, division, categories) ->
  report = ''
  divisionWinners = winners[division]

  if not divisionWinners
    return report

  divisionName = data_types.divisionName(division)
  report += divisionName + ',,,,\n'

  for category in categories
    categoryWinners = divisionWinners[category]

    if not categoryWinners
      continue

    categoryName = data_types.entryNames[year][category]

    for place in [3,2,1]
      winner = categoryWinners[place]

      if not winner
        continue

      report += ",#{categoryName},#{placeName(place)} Place,#{winner.Registrant.firstname} #{winner.Registrant.lastname},#{winner.Entry.id}\n"

  if 'best' of divisionWinners
    winner = divisionWinners.best
    report += ",#{categoryName},Best of,#{winner.Registrant.firstname} #{winner.Registrant.lastname},#{winner.Entry.id}\n"

  return report

getWinnersReport = (request, response, next) ->
  year = request.param('year')
  winners = collateWinners(request.winners, year, (winner) -> winner)

  report = 'Division,Category,Placement,Winner,Entry\n'

  for division in data_types.divisions when division != 'junior' and division != 'child'
    report += getDivisionWinnersReport(
      year,
      winners,
      division,
      c for c in data_types.entryTypes when data_types.isDivisional(c, year))

  report += getDivisionWinnersReport(
    year,
    winners,
    'tasting',
    c for c in data_types.entryTypes when data_types.isTasting(c))

  report += getDivisionWinnersReport(
    year,
    winners,
    'showcase-single',
    data_types.singleShowcaseTypes)

  report += getDivisionWinnersReport(
    year,
    winners,
    'showcase-team',
    data_types.teamShowcaseTypes)

  if 'best' of winners
    winner = winners.best
    report += ",Show,Best of,#{winner.Registrant.firstname} #{winner.Registrant.lastname},#{winner.Entry.id}\n"

  response.send(report, {'Content-Type': 'text/csv'}, 200)

postWinner = (request, response, next) ->
  response.json(
    ok: true
  )

exports.DatabaseMiddleware = class DatabaseMiddleware
  constructor: (cakeshowDB) ->
    this.cakeshowDB = cakeshowDB

  shows: (request, response, next) =>
    this.cakeshowDB.cakeshowDB.query('SELECT distinct year as `year` FROM `Signups`', { type: 'SELECT'})
    .then( (years) ->
      request.shows = [year.year for year in years]
      next()
    )
    .catch( (error) ->
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
    signupFilter = {}

    if requestedYear?
      signupFilter.year = requestedYear

    search = request.param('search')
    if search?
      registrantFilter =
        $or:
          firstname:
            $like: search
          lastname:
            $like: search

    filter =
      where: registrantFilter
      include: [
        model: this.cakeshowDB.Signup
        where: signupFilter
      ]


    this.cakeshowDB.Registrant.count filter
    .then (count) =>
      {page, limit, offset} = this.attachPagination(request, count)
      filter.limit = limit
      filter.offset = offset

      console.log filter

      this.cakeshowDB.Registrant.findAll filter
      .then( (result) ->
        request.signups = for r in result
          Signup: r.Signups[0]
          Registrant: r

        next()
      )
      .catch( (error) ->
        return next(new Error('Could not fetch signups: ' + error))
      )
    .catch (error) ->
      return next(new Error('Could not count signups: ' + error))

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
    requestedAfter = request.param('after')

    if requestedYear?
      filter =
        year: requestedYear
    else
      filter = {}

    if requestedAfter?
      if filter.year?
        filter = "Signups.year = #{Sequelize.Utils.escape(requestedYear)}"
      else
        filter = ''

      filter += " AND Signups.createdAt > #{Sequelize.Utils.escape(requestedAfter)}"

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

  entryWithSignup: (request, response, next) =>
    id = parseInt(request.param('entryID'), 10)
    this.cakeshowDB.Entry.joinTo( [this.cakeshowDB.Signup,
                                   this.cakeshowDB.Registrant],
      where:
        id: id
    )
    .success( (entry) ->
      request.entry = entry[0]
      next()
    )
    .error( (error) ->
      next(new Error(error))
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

  winners: (request, response, next) =>
    filter = this.cakeshowDB.Entry.quoted('divisionPlace') + ' IS NOT NULL'

    this.cakeshowDB.Entry.joinTo( [this.cakeshowDB.Signup,
                                   this.cakeshowDB.Registrant],
      where: filter
    ).success( (winners) ->
      request.winners = winners
      next()
    ).error( (error) ->
      return next(new Error('Could not fetch winners: ' + error))
    )

  postWinner: (request, response, next) =>
    newID = parseInt(request.body.id)

    console.log 'setting winner', request.param('division'), request.param('category'), request.param('place'), newID

    this.cakeshowDB.Entry.find(newID)
    .success( (entry) =>
      entry.updateAttributes(
        divisionPlace: request.param('place')
      )
      .success( ->
        next()
      )
      .error( (error) ->
        return next(new Error('Could not update winner: ' + error))
      )
    )
    .error( (error) ->
      return next(new Error('Could not fetch entry: ' + error))
    )

  postBestOfDivision: (request, response, next) =>
    newID = parseInt(request.body.id)

    console.log 'setting best of division', request.param('division'), newID

    this.cakeshowDB.Entry.find(newID)
    .success( (entry) =>
      entry.updateAttributes(
        bestInDivision: true
      )
      .success( ->
        next()
      )
      .error( (error) ->
        return next(new Error('Could not update winner: ' + error))
      )
    )
    .error( (error) ->
      return next(new Error('Could not fetch entry: ' + error))
    )

  postBestOfShow: (request, response, next) =>
    newID = parseInt(request.body.id)

    console.log 'setting best of show', newID

    this.cakeshowDB.Entry.find(newID)
    .success( (entry) =>
      entry.updateAttributes(
        bestInShow: true
      )
      .success( ->
        next()
      )
      .error( (error) ->
        return next(new Error('Could not update winner: ' + error))
      )
    )
    .error( (error) ->
      return next(new Error('Could not fetch entry: ' + error))
    )
