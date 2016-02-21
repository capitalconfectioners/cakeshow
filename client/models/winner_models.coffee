exports.Winners = class Winners extends Backbone.Model
  url: =>
    "/shows/#{this.get('year')}/signups/winners"

  parse: (data) =>
    return _.extend(
      year: this.get('year')
      , data
    )

exports.Winner = class Winner extends Backbone.Model
  urlRoot: '/entries'

  initialize: =>
    this.bind('change:id', this.idChanged)

  toView: =>
    id: this.get('id')
    place: this.get('place')
    year: this.get('year')
    division: this.get('division')
    category: this.get('category')
    firstname: this.get('registrant')?.firstname
    lastname: this.get('registrant')?.lastname
    entry: this.get('entry')
    signup: this.get('signup')
    registrant: this.get('registrant')
    saving: this.get('saving')

  idChanged: =>
    this.set('saving', true)
    $.post(
      "/shows/#{this.get('year')}/signups/winners/#{this.get('division')}/#{this.get('category')}/#{this.get('place')}",
      {id: this.get('id')},
      (data) =>
        this.set('saving', false)
      'json'
    )
