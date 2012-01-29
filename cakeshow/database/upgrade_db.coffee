mysql = require("mysql")
cakeshowDB = require('./cakeshowDB')

exit = (message) ->
	console.log(message)
	process.exit(1)

styleMap = 
  showcasecakes: 
  	name: "showcase"
  	type: "number"
  style1: 
  	name: "style1"
  	type: "number"
  style2: 
  	name: "style2"
  	type: "number"
  style3: 
  	name: "style3"
  	type: "number"
  style4: 
  	name: "style4"
  	type: "number"
  style5: 
  	name: "style5"
  	type: "number"
  style6: 
  	name: "style6"
  	type: "number"
  style7: 
  	name: "style7"
  	type: "number"
  special1: 
  	name: "special1"
  	type: "number"
  special2: 
  	name: "special2"
  	type: "number"
  special3: 
  	name: "special3"
  	type: "number"
  special4: 
  	name: "special4"
  	type: "number"
  special5: 
  	name: "special5"
  	type: "number"
  cupcakesentries: 
  	name: "cupcakes"
  	type: "number"
  tastingcomp: 
  	name: "tasting"
  	type: "boolean"


signupMap =
	registrantid: 
		name: "registrantid"
		type: "number"
	year: 
		name: "year"
		type: "string"
	registration: 
		name: "registrationTime"
		type: "string"
	class: 
		name: "class"
		type: "string"
	childage: 
		name: "childage"
		type: "number"
	paid: 
		name: "paid"
		type: "boolean"
	totalfee: 
		name: "totalfee"
		type: "number"
	signupshowcase: 
		name: "signupshowcase"
		type: "boolean"
	hotelinfo: 
		name: "hotelinfo"
		type: "boolean"
	electricity: 
		name: "electricity"
		type: "boolean"
	paymentmethod: 
		name: "paymentmethod"
		type: "string"

mapSignup = (row, year) ->
	newRow = []
	for oldCol, newCol of signupMap
		converted = row[oldCol]
		
		switch newCol.type
			when "boolean" 
				if converted == "yes"
					converted = 1
				else
					converted = 0
			when "number"
				if typeof converted == "string"
					if converted == ""
						converted = 0
					else
						converted = parseInt(converted)
			
		
		switch newCol.name
			when "year"
				newRow.push(year)
			else
				newRow.push(converted)
	
	return newRow

class Upgrader
	cakeshowDBs : 
		"1": "2011"
		"09": "2009"
		"10": "2010"
		"12": "2012"
	
	upgrade : =>
		cakeshowDB.connect()
		
		this.upgradeRegistrants()
		for showNumber of this.cakeshowDBs
			this.upgradeCakeshow(showNumber)
	
	upgradeRegistrants : =>
		this.registrantsDB = new mysql.createClient(
			hostname: "localhost"
			user: "root"
			password: ""
			database: "capitalc_registrants"
		)
		
		this.registrantsDB.query(
			'SELECT *' +
			'FROM registrants;',
			(error,rows,columns) =>
				if error
					exit("Error: " + error)
				
				for row in rows
					newRow = {}
					for col of cakeshowDB.Registrant.rawAttributes when row[col]?
						newRow[col] = row[col]
					
					registrant = cakeshowDB.Registrant.build(newRow)
					registrant.save()
						.error( (error) ->
							console.log('Error inserting registrant: ' + error)
						)
		)

	upgradeCakeshow : (number) =>
		dbName = "capitalc_cakeshow" + number
		this[dbName] = new mysql.createClient(
			hostname: "localhost"
			user: "root"
			password: ""
			database: dbName
		)
		
		signupUpgrader = new SignupUpgrader(this, this.cakeshowDBs[number])
		
		signups = this[dbName].query(
			"SELECT *" +
			"FROM contestantsignups;",
			(error, rows, columns) ->
				for row in rows
					signupUpgrader.insertRegistrant(row)
		)

class SignupUpgrader
	constructor: (upgrader, year) ->
		this.upgrader = upgrader
		this.year = year

	insertRegistrant : (row) =>
		###
		this.upgrader.cakeshow.query()
			.insert("signups", (newCol.name for oldCol, newCol of signupMap),
				mapSignup(row, this.year))
			.execute( callback = (error, result) =>
				if error
					exit("Error inserting signup: " + error)
				
				this.insertRegistrantEntries(result.id, row)
			
		)
		###

	insertRegistrantEntries : (signupID, oldRegistrant) =>
		###
		columns = ['registrantid','signupid','year','category']
		allEntries = []
		for style, entryStyle of styleMap when oldRegistrant[style]?
			if entryStyle.type == "number"
				for i in [0..oldRegistrant[style]]
					allEntries.push([oldRegistrant.registrantid, signupID, this.year, entryStyle.name])
			else
				allEntries.push([oldRegistrant.registrantid, signupID, this.year, entryStyle.name])
		
		this.upgrader.cakeshow.query()
			.insert("entries", columns, allEntries)
			.execute(callback = (error) ->
				if error
					console.log("Error inserting entry: " + error)
			)
		###

module.exports = new Upgrader()
