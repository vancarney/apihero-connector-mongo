{_}             = require 'lodash'
{should,expect} = require './_init'

Customer = null
describe 'mongodb connector', ->
  
  before =>
    should()
    @ds = getDataSource()
    
  it 'should connect', (done)=>
    @ds.connector.connect done
    
  it 'should have the API Hero Mixin Defined', =>
    expect( @ds.ApiHero ).to.exist
    
  it 'should obtain a list of Collections', (done)=>
    expect( @ds.ApiHero.listCollections ).to.exist
    @ds.ApiHero.listCollections.should.be.a 'function'
    @ds.ApiHero.listCollections (e,names)=>
      throw e if e?
      names.length.should.eq 3
      done.apply @, arguments
    # @ds.connector.db.collections (e,cols)=> 
      # (c = _.map _.pluck( cols, 's'), (v)-> v.name).length.should.eq 2
      # console.log c
      # done.apply @, arguments
  it 'should fiilter the list of Collections', (done)=>
    @ds.ApiHero.listCollections (e,names)=>
      filtered = _.compact _.map names, (v)=>
        if v.match new RegExp "^(#{@ds.ApiHero.exclude.join '|'})$" then null else v
      expect( filtered.indexOf 'system.indexes').to.eq -1
      done()
        
  it 'should have the discoverCollections Method Defined', (done)=>
    expect( @ds.ApiHero.discoverCollections ).to.exist
    @ds.ApiHero.discoverCollections.should.be.a 'function'
    @ds.ApiHero.discoverCollections (e,trees)=>
      trees.name.should.eq 'String'
      # trees.emails.should.eq 'Array'
      # trees.age.should.eq 'Number'
      done.apply @, arguments

  

  # it 'should list collection', =>
    # # console.log @db
    
