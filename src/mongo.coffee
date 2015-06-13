{_}            = require 'lodash'
Serializable   = require './serializable'
MongoConnector = require 'loopback-connector-mongodb'
class MongoDB
  'use strict'
  exclude:['_+.*', 'system\.indexes+', 'migrations+']
  constructor:(@dataSource, @db)->
  getCollection:(name,callback)->
    @db.collection name, callback
  renameCollection:(name, newName, opts, callback)->
    throw 'callback required' unless arguments.length and typeof arguments[arguments.length - 1] is 'function'
    if typeof opts is 'function'
      callback = arguments[2]
      opts = {}
    callback 'new name is required at arguments[1]' unless typeof newName is 'string' and newName.length
    @getCollection name, (e,col)=>
      col.rename newName, opts, callback
  dropCollection:(name,callback)->
    throw 'callback required' unless arguments.length and typeof arguments[arguments.length - 1] is 'function'
    return callback 'name required' unless name? and typeof name is 'string'
    @getCollection name, (e,col)=>
      col.drop callback
  discoverCollections:(callback)->
    throw 'callback required' unless arguments.length and typeof arguments[arguments.length - 1] is 'function'
    trees = {}
    @db.collections (e,cols)=>
      done = _.after cols.length, => callback null, trees
      for collection in cols
        @deriveSchema collection, (e,tree)=>
          return callback.apply @, arguments if e?
          _.extend trees, (o={})[collection.s.name.split().pop()] = tree
          done()
  listCollections:(callback)->
    throw 'callback required' unless arguments.length and typeof arguments[arguments.length - 1] is 'function'
    @db.collections (e,cols)=>
      callback.apply @, if e? then [e] else [null, _.map _.pluck( cols, 's'), (v)-> v.name]
  deriveSchema:(collection, callback)->
    throw 'callback required' unless arguments.length and typeof arguments[arguments.length - 1] is 'function'
    return callback 'collection is required' unless collection
    unless (t = typeof collection).match /^(string|object)$/
      return callback "collection is expected to be type String or Object. Type was #{t}" 
    types = {}
    tree = {}
    compare = (a, b)->
      return 1 if (a[1] < b[1] )
      return -1 if (a[1] > b[1])
      0
    handler = (e,col) =>
      return callback? e, null if e?
      col.find {}, {}, (e,res)=>
        return callback? e if e?
        res.toArray (e,arr)=>
          for record in arr
            branch = (new Serializable record).serialize()
            for key,value of branch
              types[key] ?= {}
              types[key][value] = if types[key][value]? then types[key][value] + 1 else 1
          for field, type of types
            tPair = _.pairs type
            if tPair.length > 1
              tPair.sort compare
              type = if ((tPair[0][1]/tPair[1][1])*100 > 400) then tPair[0][0] else 'Mixed'
            else
              type = tPair[0][0]
            tree[field] = type
          return callback? null, tree
    #handles colletion name as param 1 
    return @getCollection( collection, handler ) if typeof collection is 'string'
    # handles collection instance as param 1
    return handler( null, collection ) if typeof collection is 'object'
    # returns error if unable to handle collection param
    callback 'collection parameter was invalid'
  createCollection: (name, json, opts, callback)->
    throw 'callback required' unless arguments.length and typeof arguments[arguments.length - 1] is 'function'
    opts = idInjection: true if typeof opts is 'function'
    callback ?= arguments[arguments.length - 1]
    return @db.createCollection name, arguments[1] if arguments.length is 2
    try
      @dataSource.buildModelFromInstance.apply @dataSource, _.initial arguments
    catch e
      return callback e
    @createCollection name, callback
exports.initialize = (dataSource, callback)=>
  throw 'callback required' unless arguments.length and typeof arguments[arguments.length - 1] is 'function'
  MongoConnector.initialize dataSource, (e,db)=>
    return callback.apply @, arguments if e?
    _.extend dataSource, ApiHero: new MongoDB dataSource, db
    callback.apply @, [null,db]
    
    

    