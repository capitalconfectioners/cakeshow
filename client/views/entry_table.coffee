entryTableTemplate = require('./templates/entry_table')
entryRowTemplate = require('./templates/entry_row')

exports.EntryRowView = class EntryRowView extends Backbone.View
  tagName: 'tr'

  render: =>
    this.$el.html(entryRowTemplate.render(this.model.toJSON()))
    return this

exports.EntryTableView = class EntryTableView extends Backbone.View
  initialize: (options) =>
    this.collection.bind('reset', this.render)
    this.collection.bind('add', this.add)

  render: =>
    this.$el.html(entryTableTemplate.render())

    this.add(entry) for entry in this.collection.models

    return this

  add: (entry) =>
    view = new EntryRowView(model: entry)
    this.$el.find('tbody').append(view.render().el)

  title: =>
    return "Cakeshow #{this.collection.year} Entries"