Sequelize = require('sequelize')
Joinalize = require('../lib/joinalize')

cakeshowTypes = require('../shared/data_types')


parseURL = (url) ->
  parsedURI = url.match(/mysql:\/\/(\w+):(\w+)@([^:]+):(\d+)\/(\w+)/)
  return {
    username: parsedURI[1]
    password: parsedURI[2]
    host: parsedURI[3]
    port: parseInt(parsedURI[4])
    database: parsedURI[5]
  }

class CakeshowDB
  connect: (url, options={}) =>
    {database, username, password, host, port} = parseURL(url)
    dbOptions =
      logging: options.verbose
      host: host
      port: port

    this.cakeshowDB = new Sequelize(database, username, password, dbOptions)

    this.Registrant = this.cakeshowDB.define('Registrant',
      firstname: Sequelize.STRING
      lastname: Sequelize.STRING
      address: Sequelize.STRING
      city: Sequelize.STRING
      state: Sequelize.STRING
      zipcode: Sequelize.STRING
      email: Sequelize.STRING
      phone: Sequelize.STRING
      dateregistered: Sequelize.DATE
      password: Sequelize.STRING
    )

    this.Signup = this.cakeshowDB.define('Signup',
      year: Sequelize.STRING
      registrationTime:
        type: Sequelize.STRING
        validate: {isIn: ['early','late','student','child']}
      'class':
        type: Sequelize.STRING
        validate: {isIn: cakeshowTypes.divisions}
      childage: Sequelize.INTEGER
      paid:
        type: Sequelize.BOOLEAN
        default: false
      totalfee: Sequelize.INTEGER
      signupshowcase:
        type: Sequelize.BOOLEAN
        default: false
      hotelinfo:
        type: Sequelize.BOOLEAN
        default: false
      electricity:
        type: Sequelize.BOOLEAN
        default: false
      paymentmethod:
        type: Sequelize.STRING
        validate: {isIn: ['instore','mail','paypal']}
    )

    this.Entry = this.cakeshowDB.define('Entry',
      year: Sequelize.STRING
      category:
        type: Sequelize.STRING
        validate: {isIn: cakeshowTypes.entryTypes}
      didBring:
        type: Sequelize.BOOLEAN
        default: false
      styleChange:
        type: Sequelize.BOOLEAN
        default: false
      entryNumber: Sequelize.INTEGER
    )

    this.Registrant.hasMany(this.Signup, as: 'Signups')
    this.Signup.belongsTo(this.Registrant, as: 'Registrant')

    this.Signup.hasMany(this.Entry, as: 'Entries')
    this.Entry.belongsTo(this.Signup, as: 'Signup')

    Joinalize.register(this.cakeshowDB)
    this.cakeshowDB.sync()

module.exports = new CakeshowDB()
