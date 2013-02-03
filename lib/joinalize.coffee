unambiguousAttributes = (model) ->
  result = []
  for column of model.rawAttributes
    result.push([model.quoted(column), model.qualified(column)])
  return result

joinAttributes = (tables) ->
  attributes = []

  for table in tables
    attributes = attributes.concat(unambiguousAttributes(table))

  return attributes

allTables = (source, targets) ->
  tableNames = [source.tableName]
  for table in targets
    tableNames.push(table.tableName)

  return tableNames

class JoinedResultFactory
  constructor: (source,targets) ->
    this.tables = [source].concat(targets)
  
  build: (values, options) =>
    individualValues = {}

    for table in this.tables
      individualValues[table.tableName] = {}

    for key, value of values
      [table,column] = key.split('.')

      individualValues[table][column] = value
    
    result = {}

    for table in this.tables
      result[table.name] = table.build(individualValues[table.tableName])
    
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
  
  factory._buildJoinOptions = (targets, options = {}) ->
    tables = [this].concat(targets)

    options.attributes = (options.attributes ? []).concat(joinAttributes(tables))

    associations = []

    for target in targets
      for table in tables
        association = null

        for name, assc of table.associations
          if assc.target.tableName == target.tableName
            association = assc
            break

        if association?
          break

      if not association?
        throw new Error("Could not find association mapping #{target.name} to any of #{tables}");

      associations.push(association)

    if typeof options.where != 'string' and not Array.isArray(options.where)
      newWhere = {}

      for association in associations
        newWhere[association.source.qualified(association.identifier)] =
          join: association.target.qualified('id')
      
      if typeof options.where == 'object' and not options.where.hasOwnProperty('length')
        for attr, val of options.where
          newWhere[this.qualified(attr)] = val
      else if typeof options.where == 'number'
        newWhere[this.qualified('id')] = options.where
      
      options.where = newWhere
    else if typeof options.where == 'string'
      joinClauses = []

      for association in associations
        joinClauses.append("#{association.source.quoted(association.identifier)} = #{association.target.quoted('id')}")

      options.where = "(#{options.where}) AND (#{joinClauses.join(' AND ')})"

    return options

  factory.joinTo = (Target, options = {}) ->
    targets = [].concat(Target)
    options = this._buildJoinOptions(targets, options)

    return this.QueryInterface.select(new JoinedResultFactory(this,targets), allTables(this, targets), options)
  
  factory.countJoined = (Target, options = {}) ->
    options.attributes = [['count(*)', 'count']]

    targets = [].concat(Target)
    options = this._buildJoinOptions(targets, options)
    
    factory = build: (values, options) ->
      return parseInt(values.count,10)
    
    return this.QueryInterface.select(factory, allTables(this, targets), options)
      

exports.register = (sequelize) ->
  for model in sequelize.modelFactoryManager.models
    joinalize(model)
