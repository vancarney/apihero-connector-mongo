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
    
  it 'should create a Collections', (done)=>
    @ds.ApiHero.createCollection 'RenameMe', done

  it 'should get a Collections', (done)=>
    @ds.ApiHero.getCollection 'RenameMe', (e,col)=>
      col.s.name.should.eq 'RenameMe'
      done.apply @, arguments

  it 'should obtain a list of Collections', (done)=>
    expect( @ds.ApiHero.listCollections ).to.exist
    @ds.ApiHero.listCollections.should.be.a 'function'
    @ds.ApiHero.listCollections (e,names)=>
      throw e if e?
      names.length.should.eq 2
      expect( names.indexOf 'RenameMe' ).to.be.above -1
      done.apply @, arguments

  it 'should filter the list of Collections', (done)=>
    @ds.ApiHero.listCollections (e,names)=>
      filtered = _.compact _.map names, (v)=>
        if v.match new RegExp "^(#{@ds.ApiHero.exclude.join '|'})$" then null else v
      expect( filtered.indexOf 'system.indexes').to.eq -1
      done()
      
  it 'should rename a collection', (done)=>
    @ds.ApiHero.renameCollection 'RenameMe', 'DeleteMe', =>
      @ds.ApiHero.getCollection  'DeleteMe', (e, col)=>
        expect( col ).to.exist
        done.apply @, arguments
              
  it 'should drop a collection', (done)=>
    @ds.ApiHero.dropCollection 'DeleteMe', =>
      @ds.ApiHero.listCollections (e,names)=>
        throw e if e?
        expect( names.indexOf 'DeleteMe' ).to.eq -1
        done()

  it 'should create a Collection with Data', (done)=>
    @ds.ApiHero.createCollection 'People', (d = name:'Jimmy', "age":20), (e, col)=>
      col.insert d, =>
        done.apply @, arguments
            
  it 'should have the discoverCollections Method Defined', (done)=>
    expect( @ds.ApiHero.discoverCollections ).to.exist
    @ds.ApiHero.discoverCollections.should.be.a 'function'
    @ds.ApiHero.discoverCollections (e,trees)=>
      @trees = trees
      done.apply @, arguments

  it 'should recognize name as a String', =>
    expect(@trees.name).to.exist
    @trees.name.should.eq 'String'
      
  it 'should recognize age as a Number', =>
    expect(@trees.age).to.exist
    @trees.age.should.eq 'Number'

  after (done)=>
    @ds.ApiHero.dropCollection 'People', done