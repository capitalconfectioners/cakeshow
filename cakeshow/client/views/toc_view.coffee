{TOCModel} = require('models/toc_model')

exports.TOCView = class TOCView extends Backbone.View
  events: 
    'click a.toc': 'linkClicked'
  
  initialize: ->
    this.model.bind('change', this.render)
  
  renderLevel: (level) =>
    html = "<ul>"
    for name, value of level
      html += "<li>"
      if typeof value == 'string'
        html += "<a class=\"toc\" href=\"#{value}\">#{name}</a>"
      else
        html += "#{name}" + this.renderLevel(value)
      html += "</li>"
    html += "</ul>"
    
    return html
  
  render: =>
    tocHTML = this.renderLevel(this.model.toJSON())
    this.$el.html(tocHTML)
      
  linkClicked: =>
    console.log('clicked')
