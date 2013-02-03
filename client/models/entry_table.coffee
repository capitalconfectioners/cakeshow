cakeshowTypes = require('../data_types')

exports.EntryRow = class EntryRow extends Backbone.Model
  parse: (data) =>
    return data

exports.EntryTable = class EntryTable extends Backbone.Collection
  model: EntryRow

  initialize: (options) ->
    this.url = "/shows/#{options.year}/signups/all"