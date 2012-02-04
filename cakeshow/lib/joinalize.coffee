qualified = (model, column) ->
  # Sequelize splits and re-quotes on "." in a WHERE clause
  return "#{model.tableName}.#{column}"

unambiguousAttributes = (model) ->
  result = []
  for column of model.rawAttributes
    result.push(["`#{model.tableName}`.`#{column}`","#{model.tableName}.#{column}"])
  return result

joinAttributes = (left, right) ->
  attributes = unambiguousAttributes(left).concat(unambiguousAttributes(right))
  return attributes

class JoinedResultFactory
  constructor: (source,target) ->
    this.source = source
    this.target = target
  
  build: (values, options) =>
    sourceValues = {}
    targetValues = {}
    for key, value of values
      [table,column] = key.split('.')
      
      if table == this.source.tableName
        sourceValues[column] = value
      else if table == this.target.tableName
        targetValues[column] = value
      else
        throw new Error("Could not find joined result with table name '#{table}' for result '#{key}' : '#{value}'")
    
    result = {}
    result[this.source.name] = this.source.build(sourceValues,options)
    result[this.target.name] = this.target.build(targetValues,options)
    
    return result

###
Will automatically add a joining clause if options.where is a map or number (id).

If options.where is a raw SQL string, or an array (a format string), then it must
include the joining clause.
###
joinalize = (factory) ->
  factory.joinTo = (Target, options = {}) ->
    options.attributes = options.attributes ? joinAttributes(this, Target)
    
    association = assc for name,assc of this.associations when assc.target.tableName == Target.tableName
    
    if not association?
      throw new Error("Could not find association mapping #{this.name} to #{Target.name}")
    
    if typeof options.where != 'string' and not Array.isArray(options.where)
      newWhere = {}
      
      newWhere[qualified(this,association.identifier)] = {join: qualified(Target,'id')}
      
      if typeof options.where == 'object' and not options.where.hasOwnProperty('length')
        for attr, val of options.where
          newWhere[qualified(this,attr)] = val
      else if typeof options.where == 'number'
        newWhere[qualified(this,'id')] = options.where
      
      options.where = newWhere
      
    return this.QueryInterface.select(new JoinedResultFactory(this,Target), [this.tableName,Target.tableName], options)

exports.register = (sequelize) ->
  for model in sequelize.modelFactoryManager.models
    joinalize(model)
