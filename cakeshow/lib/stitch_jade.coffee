fs = require 'fs'

exports.register = (stitch, options) ->
  try
    Jade = require 'jade'
    options = options ? client: true
    stitch.compilers.jade = (module, filename) ->
      content = Jade.compile fs.readFileSync(filename, 'utf8'), options
      module._compile content, filename
  catch err
