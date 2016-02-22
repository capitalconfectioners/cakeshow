cakeshowTypes = require('../data_types')

winnerModels = require('../models/winner_models')

categoryWinnersTemplate = require('./templates/category_winners')
bestOfWinnersTemplate = require('./templates/best_of_winners')
winnerTemplate = require('./templates/winner')

exports.AllWinners = class AllWinners extends Backbone.View
  initialize: =>
    this.model.bind('change', this.render)

  title: =>
    return this.model.get('year') + ' Winners'

  render: =>
    this.$el.html('<div class="all-winners"></div>')
    for division in cakeshowTypes.divisions when division != 'junior' and division != 'child'
      divisionView = new DivisionWinners(
        model:
          year: this.model.get('year')
          division: division
          categories: (c for c in cakeshowTypes.entryTypes when cakeshowTypes.isDivisional(c, this.model.get('year')))
          winners: this.model.get(division) ? {}
      )

      this.$el.append(divisionView.render().el)

    tastingDivisionView = new DivisionWinners(
      model:
        year: this.model.get('year')
        division: 'tasting'
        categories: (c for c in cakeshowTypes.entryTypes when cakeshowTypes.isTasting(c))
        winners: this.model.get('tasting') ? {}
    )
    this.$el.append(tastingDivisionView.render().el)

    singleShowcaseDivisionView = new DivisionWinners(
      model:
        year: this.model.get('year')
        division: 'showcase-single'
        categories: (c for c in cakeshowTypes.entryTypes when c in cakeshowTypes.singleShowcaseTypes)
        winners: this.model.get('showcase-single') ? {}
    )
    this.$el.append(singleShowcaseDivisionView.render().el)

    teamShowcaseDivisionView = new DivisionWinners(
      model:
        year: this.model.get('year')
        division: 'showcase-team'
        categories: (c for c in cakeshowTypes.entryTypes when c in cakeshowTypes.teamShowcaseTypes)
        winners: this.model.get('showcase-team') ? {}
    )
    this.$el.append(teamShowcaseDivisionView.render().el)

    bestOfShowView = new BestOfWinner(
      model:
        year: this.model.get('year')
        division: 'best'
        winners:
          best: this.model.get('best') ? {}
    )
    this.$el.append(bestOfShowView.render().el)

    return this

exports.DivisionWinners = class DivisionWinners extends Backbone.View
  tagName: 'div'
  className: 'division-winners'
  render: =>
    for category in this.model.categories
      categoryView = new CategoryWinners(
        model:
          year: this.model.year
          division: this.model.division
          category: category
          winners: this.model.winners[category] ? {}
      )

      this.$el.append(categoryView.render().el)

    bestOfView = new BestOfWinner(model: this.model)
    this.$el.append(bestOfView.render().el)

    return this

exports.BestOfWinner = class BestOfWinner extends Backbone.View
  render: =>
    this.$el.html(bestOfWinnersTemplate.render(_.extend(
      divisionName: cakeshowTypes.divisionName(this.model.division)
      , this.model
    )))

    currentWinner = this.model.winners.best

    bestInDivision = new winnerModels.Winner(
      id: currentWinner?.entry?.id
      year: this.model.year
      division: this.model.division
      category: 'best'
      place: 'best'
      entry: currentWinner?.entry
      signup: currentWinner?.signup
      registrant: currentWinner?.registrant
    )

    bestInDivisionView = new Winner(model: bestInDivision)
    this.$('tbody').append(bestInDivisionView.render().el)

    return this

exports.CategoryWinners = class CategoryWinners extends Backbone.View
  render: =>
    this.$el.html(categoryWinnersTemplate.render(_.extend(
      divisionName: cakeshowTypes.divisionName(this.model.division)
      categoryName: cakeshowTypes.entryNames[this.model.year][this.model.category]
      , this.model
    )))
    for place in [3, 2, 1]
      existingWinner = this.model.winners[place] ? {}
      winner = new winnerModels.Winner(
        id: existingWinner.entry?.id
        year: this.model.year
        division: this.model.division
        category: this.model.category
        place: place
        entry: existingWinner.entry
        signup: existingWinner.signup
        registrant: existingWinner.registrant
      )
      winnerView = new Winner(model: winner)

      this.$el.find('tbody').append(winnerView.render().el)
    return this

exports.Winner = class Winner extends Backbone.View
  tagName: 'tr'

  events:
    'change .entry': 'entryChanged'

  initialize: =>
    this.model.bind('change', this.render)

  render: =>
    this.$el.html(winnerTemplate.render(this.model.toView()))
    return this

  entryChanged: (e) =>
    this.model.set(id: parseInt(e.target.value))
    this.model.fetch()
