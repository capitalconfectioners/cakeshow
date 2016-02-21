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
      )

      this.$el.append(divisionView.render().el)

    return this

isDivisional = (category, showEntries) ->
  return category of showEntries and category != 'child' and category != 'junior' and not category.startsWith('showcase') and not category.startsWith('special')

exports.DivisionWinners = class DivisionWinners extends Backbone.View
  tagName: 'div'
  className: 'division-winners'
  render: =>
    showEntries = cakeshowTypes.entryNames[this.model.year]

    for category in cakeshowTypes.entryTypes when isDivisional(category, showEntries)
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
    this.$el.html(categoryWinnersTemplate.render(
      divisionName: cakeshowTypes.divisionNames[this.model.division]
      categoryName: cakeshowTypes.entryNames[this.model.year][this.model.category]
      , this.model
    ))
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
