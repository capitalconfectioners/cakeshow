{TOCModel} = require('models/toc_model')

exports.TOCView = class TOCView extends Backbone.View
  events: 
    'click a.toc': 'linkClicked'
  
  initialize: ->
    this.model.bind('change', this.render)
  
  renderLevel: (name, level) =>
    html = "<li class=\"nav-header\">#{name}</li>"
    for name, value of level
      if typeof value == 'string'
        html += "<li "
        if window.location.toString().indexOf(value) >= 0
          html += 'class="active"'
        html += ">"
        html += "<a href=\"#{value}\">#{name}</a>"
        html += "</li>"
      else
        html += this.renderLevel(name, value)
    return html
  
  render: =>
    tocHTML = '<ul class="nav nav-list">'
    tocHTML += this.renderLevel('Cakeshow', this.model.toJSON())
    tocHTML += '</ul>'
    this.$el.html(tocHTML)
      
  linkClicked: =>
    console.log('clicked')
