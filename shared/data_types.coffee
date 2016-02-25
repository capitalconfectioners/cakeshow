exports.entryTypes = [
  'showcase'
  'showcase2'
  'showcase3'
  'showcase4'
  'style1'
  'style2'
  'style3'
  'style4'
  'style5'
  'style6'
  'style7'
  'style8'
  'style9'
  'special1'
  'special2'
  'special3'
  'special4'
  'special5'
  'cupcakes'
  'child'
  'junior'
  ]

exports.entryNames =
  '2012':
    showcase: 'Showcakes'
    style1: 'Novelty Single'
    style2: 'Sculpted'
    style3: 'Novelty Tiered'
    style4: 'Wedding Tiered'
    style5: 'Buttercream Single'
    style6: 'Special Techniques'
    style7: 'Confections'
    special1: 'Birthday Tasting'
    special2: 'Cupcakes Tasting'
    special3: 'Renaissance Tasting'
    special4: 'Renaissance Tasting'
    special5: 'Cookies Tasting'
    child: 'Child'
    junior: 'Junior'
  '2013':
    showcase: 'Showcakes'
    style1: 'Novelty Single'
    style2: 'Sculpted'
    style3: 'Novelty Tiered'
    style4: 'Wedding Tiered'
    style5: 'Buttercream Single'
    style6: 'Special Techniques'
    style7: 'Confections'
    special1: 'Angel Food Tasting'
    special2: 'Mini-Bottle Tasting'
    special3: 'Moon Pies Tasting'
    special4: 'Cookies Tasting'
    special5: 'Candies Tasting'
    child: 'Child'
    junior: 'Junior'
  '2014':
    showcase: 'Showcakes'
    style1: 'Novelty Single'
    style2: 'Sculpted'
    style3: 'Novelty Tiered'
    style4: 'Wedding Tiered'
    style5: 'Buttercream Single'
    style6: 'Special Techniques'
    style7: 'Confections'
    special1: 'Pie/Tart/Pastry Tasting'
    special2: 'Twisted Cake Tasting'
    special3: 'Canned Item Tasting'
    special4: 'Cookies Tasting'
    special5: 'Candies Tasting'
    child: 'Child'
    junior: 'Junior'
  '2015':
    showcase: 'Showcakes'
    style1: 'Novelty Single'
    style2: 'Sculpted'
    style3: 'Novelty Tiered'
    style4: 'Wedding Tiered'
    style5: 'Buttercream Single'
    style6: 'Special Techniques'
    style7: 'Confections'
    style8: 'Dessert Table'
    style9: 'Fairy Tale Gingerbread House'
    special1: 'Little Miss Muffin'
    special2: 'Pat a Cake, Pat a Cake'
    special3: 'Blackbirds Baked in a Pie'
    special4: 'The Gingerbread Man'
    special5: 'Candy Man'
    child: 'Child'
    junior: 'Junior'
  '2016':
    showcase: 'Showcakes Sculpted Indiv'
    showcase2: 'Showcakes Sculpted Team'
    showcase3: 'Showcakes Wedding Indiv'
    showcase4: 'Showcakes Wedding Team'
    style1: 'Novelty Single'
    style2: 'Sculpted'
    style3: 'Novelty Tiered'
    style4: 'Wedding Tiered'
    style5: 'Buttercream Single'
    style6: 'Special Techniques'
    style7: 'Confections'
    style8: 'Dessert Table'
    style9: 'Cookies'
    special1: 'Pate a Choux'
    special2: 'Swiss Roll'
    special3: 'Museum inspired Desserts'
    special4: 'Cookie'
    special5: 'Candy'
    child: 'Child'
    junior: 'Junior'

exports.divisions = [
  'child'
  'junior'
  'teen'
  'culstudent'
  'adultbeg'
  'adultint'
  'adultadv'
  'professional'
  'masters'
  ]

exports.divisionNames =
  'adultint': 'Adult Intermediate'
  'culstudent': 'Culinary Student'
  'adultbeg': 'Adult Beginner'
  'professional': 'Professional'
  'junior': 'Junior'
  'adultadv': 'Adult Advanced'
  'child': 'Child'
  'teen': 'Teen'
  'masters': 'Masters'

exports.singleShowcaseTypes = ['showcase', 'showcase3']
exports.teamShowcaseTypes = ['showcase2', 'showcase4']

exports.isDivisional = (category, year) ->
  return category of exports.entryNames[year] and category != 'child' and category != 'junior' and not category.startsWith('showcase') and not category.startsWith('special')

exports.isTasting = (category) ->
  return category.startsWith('special')

exports.divisionName = (division) ->
  if division of exports.divisionNames
    exports.divisionNames[division]
  else if division == 'tasting'
    'Tasting'
  else if division == 'showcase-single'
    'Individual Showcase'
  else if division == 'showcase-team'
    'Team Showcase'
  else if division == 'best'
    'Show'
