cakeshowTypes = require('../data_types')

# allWinnersTemplate = require('./templates/all_winners')
# divisionWinnersTemplate = require('./templates/division_winners')
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
      winnerView = new CategoryWinner(
        model:
          year: this.model.year
          division: this.model.division
          category: this.model.category
          place: place
      )
      this.$el.find('tbody').append(winnerView.render().el)
    return this

exports.CategoryWinner = class CategoryWinner extends Backbone.View
  tagName: 'tr'
  render: =>
    this.$el.html(winnerTemplate.render(this.model))
    return this

exports.DivisionWinner = class DivisionWinner extends Backbone.View
  render: =>
    this.$el.html(winnerTemplate.render(this.model.toJSON()))
    return this

exports.ShowWinner = class ShowWinner extends Backbone.View
  render: =>
    this.$el.html(winnerTemplate.render(this.model.toJSON()))
    return this
