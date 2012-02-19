unambiguousAttributes = (model) ->
  result = []
  for column of model.rawAttributes
    result.push([model.quoted(column), model.qualified(column)])
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

If options.where is an array (a format string), then it must include the joining clause.
###
joinalize = (factory) ->
  factory.qualified = (column) ->
    # Sequelize splits and re-quotes on "." in a WHERE clause
    return "#{this.tableName}.#{column}"
  
  factory.quoted = (column) ->
    return "`#{this.tableName}`.`#{column}`"
  
  factory._buildJoinOptions = (Target, options = {}) ->
    options.attributes = (options.attributes ? []).concat(joinAttributes(this, Target))
    
    association = assc for name,assc of this.associations when assc.target.tableName == Target.tableName
    
    if not association?
      throw new Error("Could not find association mapping #{this.name} to #{Target.name}")
    
    if typeof options.where != 'string' and not Array.isArray(options.where)
      newWhere = {}
      
      newWhere[this.qualified(association.identifier)] = {join: Target.qualified('id')}
      
      if typeof options.where == 'object' and not options.where.hasOwnProperty('length')
        for attr, val of options.where
          newWhere[this.qualified(attr)] = val
      else if typeof options.where == 'number'
        newWhere[this.qualified('id')] = options.where
      
      options.where = newWhere
    else if typeof options.where == 'string'
      options.where = "(#{options.where}) AND (#{this.quoted(association.identifier)} = #{Target.quoted('id')})"
      
    return options
  
  factory.joinTo = (Target, options = {}) ->
    options = this._buildJoinOptions(Target, options)
    
    return this.QueryInterface.select(new JoinedResultFactory(this,Target), [this.tableName,Target.tableName], options)
  
  factory.countJoined = (Target, options = {}) ->
    options.attributes = [['count(*)', 'count']]
    
    options = this._buildJoinOptions(Target, options)
    
    factory = build: (values, options) ->
      return parseInt(values.count,10)
    
    return this.QueryInterface.select(factory, [this.tableName,Target.tableName], options)
      

exports.register = (sequelize) ->
  for model in sequelize.modelFactoryManager.models
    joinalize(model)
