cakeshowTypes = require('../data_types')

# allWinnersTemplate = require('./templates/all_winners')
# divisionWinnersTemplate = require('./templates/division_winners')
categoryWinnersTemplate = require('./templates/category_winners')
winnerTemplate = require('./templates/winner')

exports.AllWinners = class AllWinners extends Backbone.View
  tagName: 'div'
  className: 'all-winners'

  title: =>
    return this.model.year + ' Winners'

  render: =>
    for division in cakeshowTypes.divisions
      divisionView = new DivisionWinners(
        model:
          year: this.model.year
          division: division
      )

      this.$el.append(divisionView.render().el)

    return this

exports.DivisionWinners = class DivisionWinners extends Backbone.View
  tagName: 'div'
  className: 'division-winners'
  render: =>
    showEntries = cakeshowTypes.entryNames[this.model.year]

    for category in cakeshowTypes.entryTypes when category in showEntries and category != 'child' and category != 'junior'
      categoryView = new CategoryWinners(
        model:
          year: this.model.year
          division: division
          category: category
      )

      this.$el.append(divisionView.render().el)

exports.CategoryWinners = class CategoryWinners extends Backbone.View
  tagName: 'table'
  className: 'category-winners'
  render: =>
    this.$el.html(categoryWinnersTemplate.render(this.model.toJSON()))
    for place in [3, 2, 1]
      winnerView = new CategoryWinner(
        model:
          year: this.model.year
          division: this.model.division
          category: this.model.category
          place: place
      )
      this.$el.append(winnerView.render().el)
    return this

exports.CategoryWinner = class CategoryWinner extends Backbone.View
  tagName: 'tr'
  render: =>
    this.$el.html(winnerTemplate.render(this.model.toJSON()))
    return this

exports.DivisionWinner = class DivisionWinner extends Backbone.View
  render: =>
    this.$el.html(winnerTemplate.render(this.model.toJSON()))
    return this

exports.ShowWinner = class ShowWinner extends Backbone.View
  render: =>
    this.$el.html(winnerTemplate.render(this.model.toJSON()))
    return this
