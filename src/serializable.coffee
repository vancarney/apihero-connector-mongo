{_} = require 'lodash'
{ObjectID, Binary} = require 'mongodb'

class Serializable extends Object
  __data:{}
  constructor:(data, opts={})->
    @errors = null
    @__schema = opts.schema || {validators:{}}
    @setData data if data
  setData:(data)->
    _.each data, (v,k)=> 
      v = v.replace /\0/g, '' if typeof v is 'string'
    @__data = data
  validate:->
    if process.env != 'development'
      for k,v of attrs
        if (path = @__schema.paths[ k ])?
          for validator in path.validators || []
            return validator[1] unless (validator[0] v)
        else
          return "#{@className} has no attribute '#{k}'" if k != @idAttribute
    return
  isValid:->
    (valid = @validate()) == undefined || valid is null
  valueOf:->
    @toJSON()
  toJSON:->
    if @isValid() then @__data else null
  serialize:(maxDepth)->
    branch = {}
    serialize = (doc, parentKey, maxDepth)=>
      for key,value of doc
        continue if key.match /^(v|ns)$/
        branch[subKey = "#{parentKey}#{key}"] = Serializable.getMongoType value
        serialize value, "#{subKey}.", maxDepth - 1 if (Serializable.isHash value) and (maxDepth > 0)
    serialize @__data, '', maxDepth
    branch
Serializable.isHash = (value)->
  if typeof value == 'object'
    return !(Array.isArray value or value instanceof Date or value instanceof ObjectId or value instanceof BinData)
  false
Serializable.getMongoType = (obj)->
  throw 'Serializable.getMongoType() requires an object argument' if obj == undefined
  return 'null' if (obj = arguments[0]) is null
  return "#{type.charAt(0).toUpperCase()}#{type.slice(1)}" if (type = typeof obj) != 'object'
  return 'Array' if obj && obj.constructor == Array
  return 'Date' if obj instanceof Date
  if (obj instanceof Binary)
      BinaryTypes = {}
      BinaryTypes[0x00] = 'generic'
      BinaryTypes[0x01] = 'function'
      BinaryTypes[0x02] = 'old'
      BinaryTypes[0x03] = 'UUID'
      BinaryTypes[0x05] = 'MD5'
      BinaryTypes[0x80] = 'user'
      return "Binary-#{BinaryTypes[obj.subtype()]}"
  return 'ObjectID' if typeof obj.hasOwnProperty 'getTimestamp' is 'function' and obj.getTimestamp() instanceof Date
  return 'Object'
module.exports = Serializable