Sequelize = require('sequelize')
Joinalize = require('../lib/joinalize')

validations = require('../shared/validations')

class CakeshowDB
	connect: (username='root', password='', logging=false) =>
		this.cakeshowDB = new Sequelize('cakeshow', username, password,
			logging: logging
		)
		
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
				validate: {isIn: ['adultint','culstudent','adultbeg','professional','junior','adultadv','child','teen','masters']}
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
			category:
				type: Sequelize.STRING
				validate: {isIn: validations.entryTypes}
			didBring: 
				type: Sequelize.BOOLEAN
				default: false
			styleChange: 
				type: Sequelize.BOOLEAN
				default: false
		)
		
		this.Registrant.hasMany(this.Signup, as: 'Signups')
		this.Signup.belongsTo(this.Registrant, as: 'Registrant')
		
		this.Signup.hasMany(this.Entry, as: 'Entries')
		this.Entry.belongsTo(this.Signup, as: 'Signup')
		
		Joinalize.register(this.cakeshowDB)
		this.cakeshowDB.sync()

module.exports = new CakeshowDB()
