exports.PagedListView = class PagedListView extends Backbone.View
  register: (name) =>
    this.listLinkName = name
    this.events = this.events ? []
    this.events["click #next-#{this.listLinkName}:not(.disabled)"] = 'next'
    this.events["click #prev-#{this.listLinkName}:not(.disabled)"] = 'prev'
    
  render: =>
    if this.collection.next?
      this.$el.find("li.next a").removeClass('disabled')
    else
      this.$el.find("li.next a").addClass('disabled')
          
    if this.collection.prev?
      this.$el.find("li.previous a").removeClass('disabled')
    else
      this.$el.find("li.previous a").addClass('disabled')
      
    return this
  
  next: =>
    app.router.navigate(this.collection.next, trigger: true)
  
  prev: =>
    app.router.navigate(this.collection.prev, trigger: true)
    