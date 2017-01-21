Sequelize = require('sequelize')
mysql = require('mysql')

cakeshowTypes = require('../shared/data_types')


class CakeshowDB
  connect: (url, options={}) =>
    logger = if options.verbose then console.log else null
    dbOptions =
      logging: logger

    this.cakeshowDB = new Sequelize(url, dbOptions)

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
        validate: {isIn: [['early','late','student','child']]}
      'class':
        type: Sequelize.STRING
        validate: {isIn: [cakeshowTypes.divisions]}
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
        validate: {isIn: [['instore','mailin','paypal', 'full', 'multi', '']]}
    )

    this.Entry = this.cakeshowDB.define('Entry',
      year: Sequelize.STRING
      category:
        type: Sequelize.STRING
        validate: {isIn: [cakeshowTypes.entryTypes]}
      didBring:
        type: Sequelize.BOOLEAN
        default: false
      styleChange:
        type: Sequelize.BOOLEAN
        default: false
      entryNumber: Sequelize.INTEGER
      divisionPlace: Sequelize.INTEGER
      bestInDivision:
        type: Sequelize.BOOLEAN
        default: false
      bestInShow:
        type: Sequelize.BOOLEAN
        default: false
    )

    this.Registrant.hasMany(this.Signup)

    this.Signup.hasMany(this.Entry)

    this.cakeshowDB.sync(logging: logger)
    .then () =>
      console.log('Database Synced')


module.exports = new CakeshowDB()
