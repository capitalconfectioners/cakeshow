cakeshowTypes = require('../data_types')

winnerModels = require('../models/winner_models')

categoryWinnersTemplate = require('./templates/category_winners')
winnerTemplate = require('./templates/winner')

exports.AllWinners = class AllWinners extends Backbone.View
  title: =>
    return this.model.year + ' Winners'

  render: =>
    this.$el.html('<div class="all-winners"></div>')
    for division in cakeshowTypes.divisions when division != 'junior' and division != 'child'
      divisionView = new DivisionWinners(
        model:
          year: this.model.year
          division: division
          categories: (c for c in cakeshowTypes.entryTypes when cakeshowTypes.isDivisional(c, this.model.year))
      )

      this.$el.append(divisionView.render().el)

    tastingDivisionView = new DivisionWinners(
      model:
        year: this.model.year
        division: 'Tasting'
        categories: (c for c in cakeshowTypes.entryTypes when cakeshowTypes.isTasting(c))
    )
    this.$el.append(tastingDivisionView.render().el)

    showcaseDivisionView = new DivisionWinners(
      model:
        year: this.model.year
        division: 'Showcase'
        categories: (c for c in cakeshowTypes.entryTypes when cakeshowTypes.isShowcase(c))
    )
    this.$el.append(showcaseDivisionView.render().el)
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
      )

      this.$el.append(categoryView.render().el)

    return this

exports.CategoryWinners = class CategoryWinners extends Backbone.View
  render: =>
    this.$el.html(categoryWinnersTemplate.render(_.extend(
      divisionName: cakeshowTypes.divisionNames[this.model.division]
      categoryName: cakeshowTypes.entryNames[this.model.year][this.model.category]
      , this.model
    )))
    for place in [3, 2, 1]
      winner = new winnerModels.Winner(
        year: this.model.year
        division: this.model.division
        category: this.model.category
        place: place
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
    console.log 'rendering', this.model.toJSON()
    this.$el.html(winnerTemplate.render(this.model.toJSON()))
    return this

  entryChanged: (e) =>
    console.log 'entry changed', e
    this.model.set(id: parseInt(e.target.value))
    this.model.fetch()
