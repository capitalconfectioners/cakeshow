exports.PagedListView = class PagedListView extends Backbone.View
  register: (name) =>
    this.listLinkName = name
    this.events = this.events ? []
    this.events["click #next-#{this.listLinkName}"] = 'next'
    this.events["click #prev-#{this.listLinkName}"] = 'prev'
    
  render: =>
    this.$el.find("#next-#{this.listLinkName}").button(disabled: not this.collection.next?)
    this.$el.find("#prev-#{this.listLinkName}").button(disabled: not this.collection.prev?)
    return this
  
  next: =>
    app.router.navigate(this.collection.next, trigger: true)
  
  prev: =>
    app.router.navigate(this.collection.prev, trigger: true)
    