# Note: this does not create entries for Child or Juniors, but it
# should create one entry.
#
# Also note that, on bluehost, I created a single DB to store the
# ported data from the old website, so the DB name generation logic
# has been messed with, but the overall logic has not. Most
# dangerously, this means that it's possible to accidentally duplicate
# entries across years, if you simply add to the cakeshowDBs map

mysql = require("mysql")
Sequelize = require('sequelize')

exit = (message) ->
  console.log(message)
  process.exit(1)

styleMap =
  showcasecakes: "showcase"
  style1: "style1"
  style2: "style2"
  style3: "style3"
  style4: "style4"
  style5: "style5"
  style6: "style6"
  style7: "style7"
  style8: "style8"
  style9: "style9"
  special1: "special1"
  special2: "special2"
  special3: "special3"
  special4: "special4"
  special5: "special5"
  cupcakesentries: "cupcakes"


signupColumnMap =
  registrationTime: "registration"
  RegistrantId: "registrantid"

class Upgrader
  cakeshowDBs :
    "15": "2015"

  constructor: (username='root', password='', hostname='localhost', database='cakecuba_import15') ->
    this.upgradeDB = database
    this.upgradeUsername = username
    this.upgradePassword = password
    this.upgradeHostname = hostname

  upgrade : (cakeshowDB, onSuccess= ->) =>
    this.cakeshowDB = cakeshowDB

    this.cakeshowDB.cakeshowDB.query(
      'SELECT id from Registrants',
      undefined,
      raw: true
    )
      .success((data) =>
        existing = []
        for row in data
          existing.push(row.id)
        this.upgradeRegistrants(existing, =>
          showsToUpgrade = Object.keys(this.cakeshowDBs).length
          completed = 0
          for showNumber of this.cakeshowDBs
            this.upgradeCakeshow(showNumber, ->
              completed++
              console.log("Completed upgrading #{completed} years")
              if completed == showsToUpgrade
                onSuccess()
            )
        )
      )

  upgradeRegistrants : (existing, onSuccess= ->) =>
    this.registrantsDB = new mysql.createClient(
      hostname: this.upgradeHostname
      user: this.upgradeUsername
      password: this.upgradePassword
      database: this.upgradeDB
    )

    registrantQuery = 'SELECT * FROM registrants'
    if existing.length > 0
      registrantQuery += " WHERE id NOT IN (#{existing.join(',')})"
    registrantQuery += ';'

    this.registrantsDB.query(
      registrantQuery,
      (error,rows,columns) =>
        if error
          exit("Error: " + error)

        console.log("Adding #{rows.length} registrants")

        registrantChain = new Sequelize.Utils.QueryChainer

        for row in rows
          newRow = {}
          for col of this.cakeshowDB.Registrant.rawAttributes when row[col]?
            newRow[col] = row[col]

          registrant = this.cakeshowDB.Registrant.build(newRow)

          registrantChain.add(registrant.save())

        registrantChain.run()
          .error( (error) ->
            console.log('Error inserting registrant: ' + error)
          )
          .success( =>
            console.log("Registrants done")
            this.registrantsDB.end()
            onSuccess()
          )
    )

  upgradeCakeshow : (number, onSuccess= ->) =>
    year = this.cakeshowDBs[number]
    dbName = "capitalc_cakeshow" + number
    this[dbName] = new mysql.createClient(
      hostname: this.upgradeHostname
      user: this.upgradeUsername
      password: this.upgradePassword
      database: this.upgradeDB
    )

    signupUpgrader = new SignupUpgrader(this, this.cakeshowDBs[number])

    this[dbName].query(
      "SHOW TABLES like 'contestantsignups';",
      (error, rows, columns) =>
        if rows? and rows.length > 0
          this[dbName].query(
            "SELECT * FROM contestantsignups;",
            (error, rows, columns) =>
              if error?
                console.log("Error upgrading #{dbName}: " + error)
                onSuccess()
              else
                signupChainer = new Sequelize.Utils.QueryChainer
                signups = []

                for row in rows
                  signupMap =
                    row: row
                    signup: signupUpgrader.createSignup(row)

                  signupChainer.add(signupMap.signup.save())
                  signups.push(signupMap)

                console.log("Adding #{rows.length} signups from #{year}")

                signupChainer.run()
                .success( =>
                  console.log("Signups added for #{year}")

                  entryChain = new Sequelize.Utils.QueryChainer
                  entryCount = 0

                  for signupMap in signups
                    entries = signupUpgrader.createEntries(entryChain, signupMap.signup, signupMap.row)
                    signupMap.entries = entries
                    entryCount += entries.length

                  console.log("Creating #{entryCount} entries for #{year}")

                  entryChain.run()
                  .success( =>
                    console.log("Entries created for #{year}")

                    addEntriesChain = new Sequelize.Utils.QueryChainer

                    for signupMap in signups
                      addEntriesChain.add(signupMap.signup.setEntries(signupMap.entries))

                    console.log("Linking entries to signups for #{year}")

                    addEntriesChain.run()
                    .success( =>
                      console.log("Entries linked to signups for #{year}")
                      this[dbName].end()
                      onSuccess()
                    )
                    .error( (err) =>
                      console.log("Error linking entries to signups for #{year}: " + err)
                      this[dbName].end()
                      onSuccess()
                    )
                  )
                  .error( (err) =>
                    console.log("Error creating entries for #{year}: " + err)
                    this[dbName].end()
                    onSuccess()
                  )
                )
                .error( (err) =>
                  console.log("Error creating signups for #{year}: " + err)
                  this[dbName].end()
                  onSuccess()
                )
          )
        else
          console.log("No signups from #{this.cakeshowDBs[number]}")
          onSuccess()
    )

class SignupUpgrader
  constructor: (upgrader, year) ->
    this.upgrader = upgrader
    this.year = year
    this.cakeshowDB = upgrader.cakeshowDB

  createSignup : (row) =>
    return this.cakeshowDB.Signup.build(this.mapSignup(row, this.year))

  createEntries : (entryChain, signup, oldRegistrant, onSuccess= ->) =>

    entries = []

    for style, entryStyle of styleMap when oldRegistrant[style]? and oldRegistrant[style] != ''
      count = oldRegistrant[style] ? 0
      if count > 0
        for i in [0..count-1]
          entry = this.cakeshowDB.Entry.build(
            year: this.year
            category: entryStyle
            didBring: false
            styleChange: false
          )
          entryChain.add(entry.save())
          entries.push(entry)

    if signup.class == 'child' or signup.class == 'junior'
      entry = this.cakeshowDB.Entry.build(
        year: this.year
        category: signup.class
        didBring: false
        styleChange: false
      )
      entryChain.add(entry.save())
      entries.push(entry)

    return entries

  mapSignup: (row, year) =>
    newRow = {}
    for newCol, colInfo of this.cakeshowDB.Signup.rawAttributes when newCol != 'id'
      oldCol = signupColumnMap[newCol] ? newCol

      if row[oldCol]?
        type = colInfo.type ? colInfo

        converted = row[oldCol]

        switch type
          when Sequelize.BOOLEAN
            if converted == "yes"
              converted = true
            else
              converted = false
          when Sequelize.INTEGER
            if typeof converted == "string"
              if converted == ""
                converted = 0
              else
                converted = parseInt(converted,10)

        newRow[newCol] = converted

    newRow.year = year

    return newRow

module.exports = Upgrader
