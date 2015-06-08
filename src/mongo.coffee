{_}            = require 'lodash'
Serializable   = require './serializable'
MongoConnector = require 'loopback-connector-mongodb'

class MongoDB
  'use strict'
  exclude:[/^_+.*$/, /^indexes+$/, /^migrations+$/]
  constructor:(@dataSource, @db)->
  getCollection:(name,callback)->
    @db.collections.apply @, arguments
  discoverCollections:(callback)->
    trees = {}
    @db.collections (e,cols)=>
      done = _.after cols.length, => callback null, trees
      for collection in cols
        @deriveSchema collection, (e,tree)=>
          return callback.apply @, arguments if e?
          _.extend trees, (o={})[collection.s.name.split().pop()] = tree
          done()
  listCollections:(callback)->
    @db.collections (e,cols)=>
      callback.apply @, if e? then [e] else [null, _.map _.pluck( cols, 's'), (v)-> v.name]
  deriveSchema:(collection, callback)->
    throw 'callback required as argument[1]' unless callback? and typeof callback is 'function' 
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
    if typeof opts is 'function'
      callback = arguments[2]
      opts = null
    @dataSource.createCollection.apply @, arguments
  buildCollection: (name, json, opts, callback)->
    if typeof opts is 'function'
      callback = arguments[2]
      opts = null
    @dataSource.buildCollection.apply @, arguments
exports.initialize = (dataSource, callback)=>
  MongoConnector.initialize dataSource, (e,db)=>
    return callback.apply @, arguments if e?
    _.extend dataSource, ApiHero: new MongoDB dataSource, db
    callback.apply @, [null,db]
    
    

    