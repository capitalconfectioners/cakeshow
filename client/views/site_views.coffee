exports.setTitle = (title) ->
  $(document).find('.page-title').text(title)
  $(document).find('title').text(title)