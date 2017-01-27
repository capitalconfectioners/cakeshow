{spawn} = require 'child_process'
require 'coffee-script/register'
db = require './database/cakeshowDB'
Upgrader = require './database/upgrade_db'

option '-r', '--replace', 'replace existing Cakeshow database'
option '-m', '--mysql [PATH]', 'specify MySQL install directory'
option '-d', '--database [DATABASE_URL]', 'specify MySQL database URL'
option '-u', '--username [OLD_DB_USERNAME]', 'specify SQL username for old DB'
option '-p', '--password [OLD_DB_PASSWORD]', 'specify SQL password for old DB'
option '-h', '--host [OLD_DB_HOST]', 'specify SQL host for old DB'
option '-n', '--name [OLD_DB_DBNAME]', 'specify SQL database for old DB'
option '-v', '--verbose', 'print verbose output'
option '-c', '--compile', 'compile coffeescript before running'
option '-w', '--watch', 'launch Coffeescript compiler in watch mode'

class ExitHandler
  constructor: (options, onSuccess) ->
    this.onSuccess = onSuccess

  onExit: (status) =>
    process.exit(1) if status != 0
    if this.onSuccess? and typeof this.onSuccess is 'function'
      this.onSuccess(this.options)

childEnv = (options) ->
  env = process.env

  if options.mysql? and process.platform == 'darwin'
    env['DYLD_LIBRARY_PATH'] = options.mysql + "/lib:" + process.env['DYLD_LIBRARY_PATH']

  return env

redirect = (proc) ->
  proc.stderr.pipe(process.stderr)
  proc.stdout.pipe(process.stdout)
  return proc

mysql = (options, args = []) ->
  if options.mysql?
    command = options.mysql + '/bin/mysql'
  else
    command = 'mysql'

  args = []

  if options.database?
    args = args.concat(['-D', options.database])

  if options.user?
    args = args.concat(['-u', options.user])

  if options.password?
    args = args.concat(['-p', options.password])

  if options.verbose?
    args.push('--verbose')

  env = childEnv(options)

  return redirect(spawn(command, args.concat(args)), { env: env })

coffee = (script, args, options) ->
  if options?
    env = childEnv(options)

  if options.watch?
    args.push('-w')

  return redirect(spawn('coffee', [script].concat(args), {env: env}))

runSqlScript = (options, script, onSuccess) ->
  handler = new ExitHandler(options, onSuccess)

  sqlProc = mysql(options, ['-e', 'source ' + script])

  sqlProc.on('exit', handler.onExit)

createCakeshowDB = (options, onSuccess = ->) ->
  db.connect(options.database, options)
  .then ->
    if options.replace?
      console.log('Overwriting previous DB')
      db.cakeshowDB.drop()
      .then ->
        # Have to sync to register the models to drop, then sync again
        # to re-create the tables.
        db.cakeshowDB.sync()
        .then ->
          onSuccess(options)
      .catch (error) ->
        console.log('Error dropping DB:', error)
    else
      onSuccess(options)
  .catch (error) ->
    console.log('Error syncing Sequelize model: ', error)

migrateData = (options, onSuccess) ->
  console.log('Migrating data')

  upgrader = new Upgrader(
    options.user, options.password, options.host, options.name)

  upgrader.upgrade(db, ->
    console.log('Done')
  )

task 'olddb', 'Create old database from backup', (options) ->
  runSqlScript(options, 'database/create_old_dbs.sql')

task 'create', 'Create cakeshow database', (options) ->
  createCakeshowDB(options)

task 'migrate', 'Migrate data into the new Cakeshow DB', (options) ->
  createCakeshowDB(options, migrateData)

task 'serve', 'Serve Cakeshow', (options) ->
  createCakeshowDB(options, ->
    coffee('cakeshow.coffee', [], options)
  )
