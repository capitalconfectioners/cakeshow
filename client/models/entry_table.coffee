cakeshowTypes = require('../data_types')

exports.EntryRow = class EntryRow extends Backbone.Model
  parse: (data) =>
    year = data.entry.year
    data.entry.category = cakeshowTypes.entryNames[year][data.entry.category]
    data.signup.class = cakeshowTypes.divisionNames[data.signup.class]
    return data

exports.EntryTable = class EntryTable extends Backbone.Collection
  model: EntryRow

  initialize: (options) ->
    this.year = options.year
    this.url = "/shows/#{this.year}/signups/all"