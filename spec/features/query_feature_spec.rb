require 'spec_helper'

feature "query", :js => true do
  
  #Sets the collection name, so it's not hardcoded
  $test_collection_name = ""
  let(:test_collection_name) do
    $test_collection_name = "test"
  end

  #populate database
  before :each do
    #Insert some data for the test
    MongoMapper.database = MONGO_TEST_DB
    coll = MongoMapper.database.collection(test_collection_name)
    coll.insert({'_id'=> BSON::ObjectId('510571677af4a25da80355c8'), 'name'=> 'Bob', 'sex' => 'Male', 'age' => 22})
    coll.insert({'_id'=> BSON::ObjectId('51243e3ca588a7ea2216d63a'), 'name'=> 'Sue', 'sex' => 'Feale', 'age' => 27})
    coll.insert({'_id'=> BSON::ObjectId('51243e3ea588a7ea2216d63c'), 'name'=> 'Zane', 'sex' => 'Male', 'age' => 1})
    coll.insert({'_id'=> BSON::ObjectId('51243e3fa588a7ea2216d63d'), 'name'=> 'Anne', 'sex' => 'Feale', 'age' => 99})
  end
  
  #clean up database
  after :each do
    MongoMapper.database.collections.each do |coll| 
      coll.remove 
    end 
  end

  def query (input, opts = {})
    within '#collection-form' do
      page.execute_script("$('#query-input').html('#{input}')")
      opts.each_pair {|k, v| page.execute_script("$('##{k}-input').html('#{v}')")}
    end

    click_button 'submit'

    within '#collection-form' do 
      find('#query-input').should have_content(input)
      opts.each_pair {|k, v| find(:css, "##{k}-input").should have_content(v)}
    end
  end

   scenario "simple query" do
    visit "/explorer/#{MONGO_TEST_DB}/collections/#{$test_collection_name}"
    input = '"name": "Bob"'
    opts = {'limit' => 10}
    query(input, opts)
    page.should have_table('results')
    page.should have_css('a', :text => '{ "_id": "510571677af4a25da80355c8", "name": "Bob", "sex": "Male", "age": 22}')
  end

  scenario "simple query with fields blacklist" do
    #navigate to collections / query page
    visit "/explorer/#{MONGO_TEST_DB}/collections/#{$test_collection_name}"
    #fill in query
    click_button 'fields'
    input = '"name": "Bob"'
    opts = {
      'fields' => '"sex": 0',
      'limit' => 10
    }
    query(input, opts)
    page.should have_table 'results'
    page.should have_css('a', :text => '{ "_id": "510571677af4a25da80355c8", "name": "Bob", "age": 22}')
  end

  scenario "simple query with fields whitelist" do
    #navigate to collections / query page
    visit "/explorer/#{MONGO_TEST_DB}/collections/#{$test_collection_name}"
    #fill in query
    click_button 'fields'
    input = '"name": "Bob"'
    opts = {
      'fields' => '"sex": 1',
      'limit' => 10
    }
    query(input, opts)
    page.should have_table 'results'
    page.should have_css('a', :text => '{ "_id": "510571677af4a25da80355c8", "sex": "Male"}')
  end
  
  scenario "simple query with explain" do
    #navigate to collections / query page
    visit "/explorer/#{MONGO_TEST_DB}/collections/#{$test_collection_name}"
    #fill in query
    click_button 'explain'
    input = '"name": "Bob"'
    opts = {'limit' => 10}
    query(input, opts)
    page.should have_css '#results'
    page.should have_css '.debug_dump'
  end

  scenario "simple query with sort" do
    visit "/explorer/#{MONGO_TEST_DB}/collections/#{$test_collection_name}"
    #fill in query
    click_button 'sort'
    input = '"name": "Bob"'
    opts = {'limit' => 10, 'sort' => '"age": 1'}
    query(input, opts)
    page.should have_table 'results'
  end

  scenario "simple query with skip" do
    visit "/explorer/#{MONGO_TEST_DB}/collections/#{$test_collection_name}"
    #fill in query
    click_button 'skip'
    input = '"sex": "Male"'
    opts = {'limit' => 10, 'skip' => 1}
    query(input, opts)
    page.should have_table 'results'
  end

end


