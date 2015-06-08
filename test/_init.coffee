module.exports = require 'chai'
MongoConnector = require '../src/mongo'
{DataSource} = require 'loopback-datasource-juggler'
config       = require('rc')('loopback', test: "mongodb": {}).test.mongodb

global.getDataSource = global.getSchema = (customConfig)->
  db = new DataSource MongoConnector, customConfig || config
  db.log = (a)-> console.log a
  db