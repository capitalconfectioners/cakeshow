Sequelize = require('sequelize')

class CakeshowDB
	connect: (username='root', password='') =>
		this.cakeshowDB = new Sequelize('cakeshow', username, password)
		
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
			paid: Sequelize.BOOLEAN
			totalfee: Sequelize.INTEGER
			signupshowcase: Sequelize.BOOLEAN
			hotelinfo: Sequelize.BOOLEAN
			electricity: Sequelize.BOOLEAN
			paymentmethod:
				type: Sequelize.STRING
				validate: {isIn: ['instore','mail','paypal']}
		)
		
		this.Entry = this.cakeshowDB.define('Entry',
			category:
				type: Sequelize.STRING
				validate: {isIn: ['showcase','style1','style2','style3','style4','style5','style6','style7','special1','special2','special3','special4','special5','cupcakes','tasting']}
			didBring: Sequelize.BOOLEAN
			styleChange: Sequelize.BOOLEAN
		)
		
		this.Registrant.hasMany(this.Signup, {as: 'Signups'})
		this.Signup.hasMany(this.Entry, {as: 'Entries'})
		
		this.cakeshowDB.sync()

module.exports = new CakeshowDB()
