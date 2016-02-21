exports.Winner = class Winner extends Backbone.Model
  urlRoot: '/entries'

  initialize: =>
    this.bind('change:id', this.idChanged)

  toJSON: =>
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
