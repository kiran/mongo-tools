require 'spec_helper'

feature "translator", :focus => true, :js => true do

  #Sets the collection name, so it's not hardcoded
  $test_collection_name = ""
  let(:test_collection_name) do
    $test_collection_name = "test"
  end

  #populate database
  before :each do
    #Insert some data for the testMongoMapper.database.name
    coll = MongoMapper.database.collection(test_collection_name)
    coll.insert({'_id'=> BSON::ObjectId('510571677af4a25da80355c8'), 'name'=> 'Bob', 'sex' => 'Male', 'age' => 22})
    coll.insert({'_id'=> BSON::ObjectId('51243e3ca588a7ea2216d63a'), 'name'=> 'Sue', 'sex' => 'Female', 'age' => 27})
    coll.insert({'_id'=> BSON::ObjectId('51243e3ea588a7ea2216d63c'), 'name'=> 'Zane', 'sex' => 'Male', 'age' => 1})
    coll.insert({'_id'=> BSON::ObjectId('51243e3fa588a7ea2216d63d'), 'name'=> 'Anne', 'sex' => 'Female', 'age' => 99})
    visit "/explorer/#{MongoMapper.database.name}/collections/#{$test_collection_name}"
  end

  #clean up database
  after :each do
    MongoMapper.connection.drop_database(Settings.mongo.database)
  end

  def translate (input, language, opts = {})
    within '#collection-form' do
      page.execute_script("$('#query-input').html('#{input}')")
      opts.each {|k, v| page.execute_script("$('##{k}-input').html('#{v}')")}
    end

    within '#collection-form' do 
      find('#query-input').should have_content(input)
      opts.each {|k, v| find(:css, "##{k}-input").should have_content(v)}
    end

    click_link 'languages'
    page.should have_selector('#languages-dropdown', visible: true)
    find(language).click
    page.should have_selector('#languages-modal', visible: true)
    page.evaluate_script "$('#query').data('CodeMirrorInstance').toTextArea();"
  end

  def validate (result) 
    find('#query').value.should == result
    click_button 'close'
    page.should have_selector('#languages-modal', visible: false)
  end

  # Ruby tests
  scenario "ruby simple query" do
    input = '"name": "Bob"'
    opts = {'limit' => 10}
    translate(input, '#ruby', opts)
    result = "require 'mongo'\n" + 
      "include Mongo\n" +
      "mongo_client = MongoClient.new\n" + 
      "db = mongo_client.db(\"mongo_tools_test\")\n" +
      "coll = db.collection(\"test\")\n" +
      "cursor = coll.find({\"name\" => \"Bob\"}, {:limit => 10})"
    validate(result)
  end

scenario "ruby query with fields" do
    click_button 'fields'
    input = '"name": "Bob"'
    opts = {
      'fields' => '"sex": 0',
      'limit' => 10
    }
    translate(input, '#ruby', opts)
    result = "require 'mongo'\n" +
             "include Mongo\n" +
             "mongo_client = MongoClient.new\n" +
             "db = mongo_client.db(\"mongo_tools_test\")\n" +
             "coll = db.collection(\"test\")\n" +
             "cursor = coll.find({\"name\" => \"Bob\"}, {:fields => {\"sex\" => 0}, :limit => 10})"
    validate(result)
  end

  scenario "ruby query with explain" do
    click_button 'explain'
    input = '"name": "Bob"'
    opts = {'limit' => 10}
    translate(input, '#ruby', opts)
    result = "require 'mongo'\n" +
             "include Mongo\n" +
             "mongo_client = MongoClient.new\n" +
             "db = mongo_client.db(\"mongo_tools_test\")\n" +
             "coll = db.collection(\"test\")\n" +
             "explanation = coll.find({\"name\" => \"Bob\"}, {:limit => 10}).explain"
    validate(result)
  end

  scenario "ruby query with sort ascending" do
    click_button 'sort'
    input = '"sex": "Female"'
    opts = {
      'sort' => '"age": 1',
      'limit' => 10
    }
    translate(input, '#ruby', opts)
    result = "require 'mongo'\n" +
       "include Mongo\n" +
       "mongo_client = MongoClient.new\n" +
       "db = mongo_client.db(\"mongo_tools_test\")\n" +
       "coll = db.collection(\"test\")\n" +
       "cursor = coll.find({\"sex\" => \"Female\"}, {:sort => [[\"age\", Mongo::ASCENDING]], :limit => 10})"
    validate(result)
  end

  scenario "ruby query with sort descending" do
    click_button 'sort'
    input = '"sex": "Female"'
    opts = {
      'sort' => '"age": -1',
      'limit' => 10
    }
    translate(input, '#ruby', opts)
    result = "require 'mongo'\n" +
       "include Mongo\n" +
       "mongo_client = MongoClient.new\n" +
       "db = mongo_client.db(\"mongo_tools_test\")\n" +
       "coll = db.collection(\"test\")\n" +
       "cursor = coll.find({\"sex\" => \"Female\"}, {:sort => [[\"age\", Mongo::DESCENDING]], :limit => 10})"
    validate(result)
  end

  scenario "ruby query with skip" do
    click_button 'skip'
    input = '"sex": "Female"'
    opts = {
      'skip' => '1',
      'limit' => 10
    }
    translate(input, '#ruby', opts)
    result = "require 'mongo'\n" +
       "include Mongo\n" +
       "mongo_client = MongoClient.new\n" +
       "db = mongo_client.db(\"mongo_tools_test\")\n" +
       "coll = db.collection(\"test\")\n" +
       "cursor = coll.find({\"sex\" => \"Female\"}, {:skip => 1, :limit => 10})"
    validate(result)
  end

  scenario "ruby all query" do
    click_button 'skip'
    click_button 'sort'
    click_button 'explain'
    input = '"name": "Bob"'
    opts = {
      'fields' => '"sex": 0',
      'sort' => '"age": -1',
      'skip' => '1',
      'limit' => 10
    }
    translate(input, '#ruby', opts)
    result = "require 'mongo'\n" +
       "include Mongo\n" +
       "mongo_client = MongoClient.new\n" +
       "db = mongo_client.db(\"mongo_tools_test\")\n" +
       "coll = db.collection(\"test\")\n" +
       "explanation = coll.find({\"name\" => \"Bob\"}, {:sort => [[\"age\", Mongo::DESCENDING]], :skip => 1, :limit => 10}).explain"
    validate(result)
  end

  scenario "ruby empty query" do
    translate('', '#ruby', {})
    result = "require 'mongo'\n" +
       "include Mongo\n" +
       "mongo_client = MongoClient.new\n" +
       "db = mongo_client.db(\"mongo_tools_test\")\n" +
       "coll = db.collection(\"test\")\n" +
       "cursor = coll.find({}, {:limit => 25})"
    validate(result)
  end

  # Python tests
  scenario "python simple query" do
    input = '"name": "Bob"'
    opts = {'limit' => 10}
    translate(input, '#python', opts)
    result = "import pymongo\n" +
      "mongo_client = pymongo.MongoClient()\n" +
      "db = mongo_client[\"mongo_tools_test\"]\n" +
      "coll = db[\"test\"]\n" +
      "cursor = coll.find({\"name\":\"Bob\"}).limit(10)"
    validate(result)
  end

scenario "python query with fields" do
    click_button 'fields'
    input = '"name": "Bob"'
    opts = {
      'fields' => '"sex": 0',
      'limit' => 10
    }
    translate(input, '#python', opts)
    result = "import pymongo\n" +
      "mongo_client = pymongo.MongoClient()\n" +
      "db = mongo_client[\"mongo_tools_test\"]\n" +
      "coll = db[\"test\"]\n" +
      "cursor = coll.find({\"name\":\"Bob\"}, {\"sex\":0}).limit(10)"
    validate(result)
  end

  scenario "python query with explain" do
    click_button 'explain'
    input = '"name": "Bob"'
    opts = {'limit' => 10}
    translate(input, '#python', opts)
    result = "import pymongo\n" +
      "mongo_client = pymongo.MongoClient()\n" +
      "db = mongo_client[\"mongo_tools_test\"]\n" +
      "coll = db[\"test\"]\n" +
      "explanation = coll.find({\"name\":\"Bob\"}).limit(10).explain()"
    validate(result)
  end

  scenario "python query with sort ascending" do
    click_button 'sort'
    input = '"sex": "Female"'
    opts = {
      'sort' => '"age": 1',
      'limit' => 10
    }
    translate(input, '#python', opts)
    result = "import pymongo\n" +
      "mongo_client = pymongo.MongoClient()\n" +
      "db = mongo_client[\"mongo_tools_test\"]\n" +
      "coll = db[\"test\"]\n" +
      "cursor = coll.find({\"sex\":\"Female\"}).sort([(\"age\", pymongo.ASCENDING)]).limit(10)"
    validate(result)
  end

  scenario "python query with sort descending" do
    click_button 'sort'
    input = '"sex": "Female"'
    opts = {
      'sort' => '"age": -1',
      'limit' => 10
    }
    translate(input, '#python', opts)
    result = "import pymongo\n" +
      "mongo_client = pymongo.MongoClient()\n" +
      "db = mongo_client[\"mongo_tools_test\"]\n" +
      "coll = db[\"test\"]\n" +
      "cursor = coll.find({\"sex\":\"Female\"}).sort([(\"age\", pymongo.DESCENDING)]).limit(10)"
    validate(result)
  end

  scenario "python query with skip" do
    click_button 'skip'
    input = '"sex": "Female"'
    opts = {
      'skip' => '1',
      'limit' => 10
    }
    translate(input, '#python', opts)
    result = "import pymongo\n" +
      "mongo_client = pymongo.MongoClient()\n" +
      "db = mongo_client[\"mongo_tools_test\"]\n" +
      "coll = db[\"test\"]\n" +
      "cursor = coll.find({\"sex\":\"Female\"}).skip(1).limit(10)"
      validate(result)
  end

  scenario "python all query " do
    click_button 'skip'
    click_button 'sort'
    click_button 'explain'
    input = '"name": "Bob"'
    opts = {
      'fields' => '"sex": 0',
      'sort' => '"age": -1',
      'skip' => '1',
      'limit' => 10
    }
    translate(input, '#python', opts)
    result = "import pymongo\n" +
      "mongo_client = pymongo.MongoClient()\n" +
      "db = mongo_client[\"mongo_tools_test\"]\n" +
      "coll = db[\"test\"]\n" +
      "explanation = coll.find({\"name\":\"Bob\"}).sort([(\"age\", pymongo.DESCENDING)]).skip(1).limit(10).explain()"
    validate(result)
  end

  scenario "python empty query" do
    translate('', '#python', {})
    result = "import pymongo\n" +
      "mongo_client = pymongo.MongoClient()\n" +
      "db = mongo_client[\"mongo_tools_test\"]\n" +
      "coll = db[\"test\"]\n" +
      "cursor = coll.find().limit(25)"
    validate(result)
  end

  # Node tests
  scenario "node simple" do
    input = '"name": "Bob"'
    opts = {'limit' => 10}
    translate(input, '#node', opts)
    result = "var MongoClient = require('mongodb').MongoClient;\n" +
      "var Server = require('mongodb').Server;\n" +
      "var mongoClient = new MongoClient(new Server('localhost', 27017));\n" +
      "mongoClient.open(function(err, mongoClient) {\n" +
      "\tvar db = mongoClient.db('mongo_tools_test');\n" +
      "\tvar cursor = db.collection('test').find({\"name\":\"Bob\"}).limit(10);\n" +
      "\tmongoClient.close();\n" +
      "});"
    validate(result)
  end

scenario "node query with fields" do
    click_button 'fields'
    input = '"name": "Bob"'
    opts = {
      'fields' => '"sex": 0',
      'limit' => 10
    }
    translate(input, '#node', opts)
    result = "var MongoClient = require('mongodb').MongoClient;\n" +
      "var Server = require('mongodb').Server;\n" +
      "var mongoClient = new MongoClient(new Server('localhost', 27017));\n" +
      "mongoClient.open(function(err, mongoClient) {\n" +
      "\tvar db = mongoClient.db('mongo_tools_test');\n" +
      "\tvar cursor = db.collection('test').find({\"name\":\"Bob\"}, {\"sex\":0}).limit(10);\n" +
      "\tmongoClient.close();\n" +
      "});"
    validate(result)
  end

  scenario "node query with explain" do
    click_button 'explain'
    input = '"name": "Bob"'
    opts = {'limit' => 10}
    translate(input, '#node', opts)
    result = "var MongoClient = require('mongodb').MongoClient;\n" +
      "var Server = require('mongodb').Server;\n" +
      "var mongoClient = new MongoClient(new Server('localhost', 27017));\n" +
      "mongoClient.open(function(err, mongoClient) {\n" +
      "\tvar db = mongoClient.db('mongo_tools_test');\n" +
      "\tdb.collection('test').find({\"name\":\"Bob\"}).limit(10).explain(function(err, explanation) {\n" +
      "\t\tmongoClient.close();\n" +
      "\t});\n" +
      "});"
    validate(result)
  end

  scenario "node query with sort ascending" do
    click_button 'sort'
    input = '"sex": "Female"'
    opts = {
      'sort' => '"age": 1',
      'limit' => 10
    }
    translate(input, '#node', opts)
    result = "var MongoClient = require('mongodb').MongoClient;\n" +
      "var Server = require('mongodb').Server;\n" +
      "var mongoClient = new MongoClient(new Server('localhost', 27017));\n" +
      "mongoClient.open(function(err, mongoClient) {\n" +
      "\tvar db = mongoClient.db('mongo_tools_test');\n" +
      "\tvar cursor = db.collection('test').find({\"sex\":\"Female\"}).sort({\"age\":1}).limit(10);\n" +
      "\tmongoClient.close();\n" +
      "});"
    validate(result)
  end

  scenario "node query with sort descending" do
    click_button 'sort'
    input = '"sex": "Female"'
    opts = {
      'sort' => '"age": -1',
      'limit' => 10
    }
    translate(input, '#node', opts)
    result = "var MongoClient = require('mongodb').MongoClient;\n" +
      "var Server = require('mongodb').Server;\n" +
      "var mongoClient = new MongoClient(new Server('localhost', 27017));\n" +
      "mongoClient.open(function(err, mongoClient) {\n" +
      "\tvar db = mongoClient.db('mongo_tools_test');\n" +
      "\tvar cursor = db.collection('test').find({\"sex\":\"Female\"}).sort({\"age\":-1}).limit(10);\n" +
      "\tmongoClient.close();\n" +
      "});"
    validate(result)
  end

  scenario "node query with skip" do
    click_button 'skip'
    input = '"sex": "Female"'
    opts = {
      'skip' => '1',
      'limit' => 10
    }
    translate(input, '#node', opts)
    result = "var MongoClient = require('mongodb').MongoClient;\n" +
      "var Server = require('mongodb').Server;\n" +
      "var mongoClient = new MongoClient(new Server('localhost', 27017));\n" +
      "mongoClient.open(function(err, mongoClient) {\n" +
      "\tvar db = mongoClient.db('mongo_tools_test');\n" +
      "\tvar cursor = db.collection('test').find({\"sex\":\"Female\"}).skip(1).limit(10);\n" +
      "\tmongoClient.close();\n" +
      "});"
    validate(result)
  end

  scenario "node query all" do
    click_button 'skip'
    click_button 'sort'
    click_button 'explain'
    input = '"name": "Bob"'
    opts = {
      'fields' => '"sex": 0',
      'sort' => '"age": -1',
      'skip' => '1',
      'limit' => 10
    }
    translate(input, '#node', opts)
    result = "var MongoClient = require('mongodb').MongoClient;\n" +
      "var Server = require('mongodb').Server;\n" +
      "var mongoClient = new MongoClient(new Server('localhost', 27017));\n" +
      "mongoClient.open(function(err, mongoClient) {\n" +
      "\tvar db = mongoClient.db('mongo_tools_test');\n" +
      "\tdb.collection('test').find({\"name\":\"Bob\"}).sort({\"age\":-1}).skip(1).limit(10).explain(function(err, explanation) {\n" +
      "\t\tmongoClient.close();\n" +
      "\t});\n" +
      "});"
    validate(result)
  end

  scenario "node empty query" do
    translate('', '#node', {})
    result = "var MongoClient = require('mongodb').MongoClient;\n" +
      "var Server = require('mongodb').Server;\n" +
      "var mongoClient = new MongoClient(new Server('localhost', 27017));\n" +
      "mongoClient.open(function(err, mongoClient) {\n" +
      "\tvar db = mongoClient.db('mongo_tools_test');\n" +
      "\tvar cursor = db.collection('test').find().limit(25);\n" +
      "\tmongoClient.close();\n" +
      "});"
    validate(result)
  end

end