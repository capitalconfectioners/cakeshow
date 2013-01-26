{PagedListView} = require('./paged_views')

RegistrantViews = require('./registrant_views')

entryTemplate = require('./templates/entry')
entryListTemplate = require('./templates/entry_list')

signupTemplate = require('./templates/signup')
registrantSignupTemplate = require('./templates/registrant_signup')
registrantSignupListTemplate = require('./templates/registrant_signup_list')

editRegistrantTemplate = require('./templates/edit_registrant')
editSignupTemplate = require('./templates/edit_signup')

addSignupTemplate = require('./templates/add_signup')

alertTemplate = require('./templates/alert')

cakeshowTypes = require('../data_types')

exports.EntryView = class EntryView extends Backbone.View
  tagName: 'tr'
  className: 'entry'
  
  events:
    'click input.didBring': 'didBringClicked'
    'click input.styleChange': 'categoryChangeClicked'
    'change select.category': 'categoryChanged'
    'keydown input.entryNumber': 'entryNumberKeyPressed'
    'change input.entryNumber': 'syncEntryNumber'
  
  initialize: =>
    this.categories = this.model.getCategories()
    this.badEntryNumber = false
  
  render: =>
    renderParams = this.model.toJSON()
    renderParams.categories = this.categories
    this.$el.html(entryTemplate.render(renderParams))
    selectedIndex = _.indexOf(this.categories, this.model.categoryName())
    this.$el.find('select.category')[0].selectedIndex = selectedIndex
    return this
  
  didBringClicked: =>
    this.model.set('didBring', this.$el.find('.didBring')[0].checked)
    this.model.save()
  
  categoryChangeClicked: =>
    this.model.set('styleChange', this.$el.find('.styleChange')[0].checked)
    this.model.save()
  
  categoryChanged: =>
    selected = this.$el.find('select.category')[0].selectedIndex
    this.model.setCategoryName(this.categories[selected])
    
    this.model.set('styleChange', true)
    this.$el.find('input.styleChange')[0].checked = true
    
    this.model.set('didBring', true)
    this.$el.find('input.didBring')[0].checked = true
    
    this.model.save()
  
  clearEntryNumberTimer: =>
    if this.entryNumTimer?
      window.clearTimeout(this.entryNumTimer)
    this.entryNumTimer = null
    this.$el.find('.sync-icon').addClass('hide')
      
  restartEntryNumberTimer: =>
    this.clearEntryNumberTimer()
    this.entryNumTimer = window.setTimeout(this.syncEntryNumber, 5000)
    this.$el.find('.sync-icon').removeClass('hide')
  
  syncEntryNumber: =>  
    numInput = this.$el.find('input.entryNumber')[0]
    if numInput.value != ''
      entryNumber = parseInt(numInput.value, 10)
      if isNaN(entryNumber)
        this.badEntryNumber = true
        #this.$el.parents('.entries').prepend(alertTemplate.render(message: 'Entry number must be a number.'))
        this.$('.error-msg').removeClass('hide')
        this.$('fieldset.entryNumber').addClass('error')
      else
        if this.badEntryNumber
          #this.$el.parents('.entries').find('.alert').alert('close')
          this.$('.error-msg').addClass('hide')
          this.$('fieldset.entryNumber').removeClass('error')
        this.badEntryNumber = false
        this.model.set('entryNumber', entryNumber)
        
        this.model.set('didBring', true)
        this.$el.find('input.didBring')[0].checked = true
        
        this.model.save()
    this.clearEntryNumberTimer()
  
  entryNumberKeyPressed: =>
    this.restartEntryNumberTimer()

exports.EntryListView = class EntryListView extends Backbone.View
  className: 'entry-list'
  
  events:
    'click .add-entry': 'createEntry'
  
  initialize: ->
    this.collection.bind('reset', this.render)
    this.collection.bind('add', this.add)
    this.collection.view = this
  
  add: (entry) =>
    view = new EntryView(model: entry)
    this.$el.find('table').append(view.render().el)
    
  render: =>
    this.$el.html(entryListTemplate.render())
    this.add(entry) for entry in this.collection.models
    
    this.$('.alert').alert()
    
    return this
  
  createEntry: =>
    this.collection.create(
      didBring: true
      styleChange: true
    , wait: true)

exports.SignupView = class SignupView extends Backbone.View
  className: 'signup'
  
  events:
    'change select.division': 'divisionChanged'
    
  initialize: =>
    this.divisions = this.model.getDivisions()
  
  render: =>
    renderParams = this.model.toJSON()
    renderParams.divisions = this.divisions
    
    this.$el.html(signupTemplate.render(renderParams))
    
    selectedIndex = _.indexOf(this.divisions, this.model.divisionName())
    this.$el.find('select.division')[0].selectedIndex = selectedIndex
    
    collapse = this.$el.find('.collapse').collapse(
      toggle: false
    ).on('show', this.loadEntries)
    return this
  
  loadEntries: =>
    unless this.entriesView?
      this.entriesView = new EntryListView(collection: this.model.getEntries())
      this.entriesView.collection.fetch()
      this.$el.find('.entries').html(this.entriesView.render().el)
  
  divisionChanged: =>
    selected = this.$el.find('select.division')[0].selectedIndex
    this.model.setDivisionName(this.divisions[selected])
    this.model.save()

exports.RegistrantSignupView = class RegistrantSignupView extends Backbone.View
  className: 'registrantSignup'
    
  initialize: =>
    this.model.bind('change', this.render)
  
  render: =>
    this.$el.html(registrantSignupTemplate.render())
    signupView = new SignupView(tagName: 'div', model: this.model.signup)
    registrantView = new RegistrantViews.RegistrantView(tagName: 'div', model: this.model.registrant)
    
    this.$el.find('.signup').append(signupView.render().el)
    this.$el.find('.registrant').append(registrantView.render().el)
    
    return this
  
  title: =>
    return this.model.registrant.fullName()

  print: ->
    printDialog = new PrintView(
      el: $('#page-modal')[0]
      model: this.model
    ).render()
  
exports.RegistrantSignupListView = class RegistrantSignupListView extends PagedListView
  el: '#content'
  
  initialize: =>
    this.registerPagination('registrant-signups')
    this.collection.bind('reset', this.render)
    this.collection.bind('add', this.add)
    this.collection.view = this
  
  add: (registrantSignup) =>
    view = new RegistrantSignupView( {tagName: 'li', model: registrantSignup} )
    this.$el.find('#registrant-signups').append(view.render().el)
    
  render: =>
    this.$el.html(registrantSignupListTemplate.render())
    
    this.add(registrantSignup) for registrantSignup in this.collection.models
    
    super()
    return this
  
  title: =>
    title = 'Signups'
    if this.collection.year?
      title += ' ' + this.collection.year
    
    return title

  print: ->
    printDialog = new PrintView(
      el: $('#page-modal')[0]
      model: this.collection
    ).render()

printTemplate = '''
  <div class="alert alert-error hide">
    <strong>Error</strong> creating the forms
  </div>
  <strong>Please wait while the forms are generated...</strong>
  <div class="progress progress-striped active">
    <div class="bar" style="width: 100%;"></div>
  </div>
  '''

exports.PrintView = class PrintView extends Backbone.View
  render: ->
    console.log('rendering')
    this.$el.find('.modal-title').text('Printing')
    this.$el.find('.modal-body').html(printTemplate)
    this.$el.find('.modal-cancel').text('Cancel')
    this.$el.find('.alert').addClass('hide')
    this.$el.modal(show: true)

    this.model.printUrl(this.downloadReady, this.downloadError)

    return this

  downloadReady: (url) =>
    console.log('download ready', url)
    this.downloadFile(url)
    this.$el.modal('hide')

  downloadError: (err) =>
    console.log('printing error', err)
    this.$el.find('.alert').removeClass('hide')

  downloadFile: (url) ->
    window.location = url

exports.EditRegistrantView = class EditRegistrantView extends Backbone.View
  render: =>
    this.$el.html(editRegistrantTemplate.render(this.model.toJSON()))
    
    Backbone.ModelBinding.bind(this)
    
    return this

exports.EditSignupView = class EditSignupView extends Backbone.View
  render: =>
    renderParams = this.model.toJSON()
    renderParams.divisions = cakeshowTypes.divisionNames
    
    console.log(renderParams.divisions)
    
    this.$el.html(editSignupTemplate.render(renderParams))
    
    Backbone.ModelBinding.bind(this)
    
    return this

exports.AddSignupView = class AddSignupView extends Backbone.View
  el: '#content'
  
  events:
    'click button.save': 'save'
    'click button.cancel': 'cancel'
  
  title: =>
    return 'Add Registrant'
  
  render: =>  
    this.$el.html(addSignupTemplate.render())
    
    if not this.editRegistrant?
      this.editRegistrant = new EditRegistrantView(
        el: '.edit-registrant'
        model: this.model.registrant
      )
    
    if not this.editSignup?
      this.editSignup = new EditSignupView(
        el: '.edit-signup'
        model: this.model.signup
      )
    this.editRegistrant.render()
    this.editSignup.render()
  
  save: =>
    console.log(this.model)
    this.model.signup.unset('class_text', silent: true)
    this.model.save({}
      wait: true
      success: (model, response) =>
        app.router.queueData('', response)
        app.router.navigate(this.model.url() + '/' + response.signup.id, trigger: true)
      error: (model, response) ->
        console.log('error saving signup: ')
        console.log(response)
    )
  
  cancel: =>
    window.history.back()
    
exports.SignupNav = class SignupNav extends Backbone.View
  searchType: 'signups'
  el: 'body'
  
  events:
    'click .navbar a.add': 'add'
    'click .navbar a.print': 'print'
  
  render: =>
    $('input#search').typeahead(
      minLength: 2
      source: this.searchSuggestions
      onselect: this.searchSelected
      property: 'value'
    )
    
    return this
    
  searchSuggestions: (typeahead, query) =>
    this.collection.search(query, (results) ->
      for result in results
        result.value = result.registrant.firstname + " " + result.registrant.lastname
      
      typeahead.process(results)
    )
  
  searchSelected: (item) =>
    app.router.navigate('/signups/' + item.signup.id, trigger: true)
  
  add: =>
    app.router.navigate(app.registrantSignups.baseUrl + '/add', trigger: true)

  print: =>
    app.router.printView()
  