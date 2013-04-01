require 'spec_helper'
require "timeout"


feature "query", :focus => true, :js => true do

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
    MongoMapper.database.collections.each do |coll|
      coll.remove
    end
  end

  def wait_for_ajax(timeout = Capybara.default_wait_time)
    wait_until(timeout) do
      page.evaluate_script 'jQuery.active == 0'
    end
  end

  def wait_until(timeout = Capybara.default_wait_time)
    Timeout.timeout(timeout) do
      sleep(0.1) until value = yield
      value
    end
  end

  def query (input, opts = {})
    within '#collection-form' do
      page.execute_script("$('#query-input').html('#{input}')")
      opts.each {|k, v| page.execute_script("$('##{k}-input').html('#{v}')")}
    end

    click_button 'submit'
    
    wait_for_ajax

    within '#collection-form' do
      find('#query-input').should have_content(input)
      opts.each {|k, v| find(:css, "##{k}-input").should have_content(v)}
    end
  end

  scenario "simple query" do
    input = '"name": "Bob"'
    opts = {'limit' => 10}
    query(input, opts)
    page.should have_table('results')
    page.should have_selector("table#results tr", :count => 1)
    result = JSON.parse(find('table#results a').text)
    expect(result['_id']).to have_text '510571677af4a25da80355c8'
    expect(result['name']).to have_text 'Bob'
    expect(result['sex']).to have_text 'Male'
    expect(result['age']).to have_text 22
  end

  scenario "simple query with fields blacklist" do
    click_button 'fields'
    input = '"name": "Bob"'
    opts = {
      'fields' => '"sex": 0',
      'limit' => 10
    }
    query(input, opts)
    page.should have_table 'results'
    page.should have_selector("table#results tr", :count => 1)
    result = JSON.parse(find('table#results a').text)
    expect(result['_id']).to have_text '510571677af4a25da80355c8'
    expect(result['name']).to have_text 'Bob'
    expect(result['age']).to have_text 22
  end

  scenario "simple query with fields whitelist" do
    click_button 'fields'
    input = '"name": "Bob"'
    opts = {
      'fields' => '"sex": 1',
      'limit' => 10
    }
    query(input, opts)
    page.should have_table 'results'
    page.should have_selector("table#results tr", :count => 1)
    result = JSON.parse(find('table#results a').text)
    expect(result['_id']).to have_text '510571677af4a25da80355c8'
    expect(result['sex']).to have_text 'Male'
  end

  scenario "simple query with explain" do
    click_button 'explain'
    input = '"name": "Bob"'
    opts = {'limit' => 10}
    query(input, opts)
    page.should have_selector('#results', :visible => true)
    page.should have_selector('.debug_dump', :visible => true)
  end

  scenario "simple query with sort ascending" do
    click_button 'sort'
    input = '"sex": "Female"'
    opts = {
      'sort' => '"age": 1',
      'limit' => 10
    }
    query(input, opts)
    page.should have_table 'results'
    page.should have_selector("table#results tr", :count => 2)
    results = [
      JSON.parse('{ "_id": "51243e3ca588a7ea2216d63a", "name": "Sue", "sex": "Female", "age": 27}'),
      JSON.parse('{ "_id": "51243e3fa588a7ea2216d63d", "name": "Anne", "sex": "Female", "age": 99}')
    ]
    count = 0
    page.all('table#results tr').each do |row|
      result = JSON.parse(row.text)
      expect(result['_id']).to have_text results[count]['_id']
      expect(result['name']).to have_text results[count]['name']
      expect(result['sex']).to have_text results[count]['sex']
      expect(result['age']).to have_text results[count]['age']
      count += 1
    end
  end

  scenario "simple query with sort descending" do
    click_button 'sort'
    input = '"sex": "Female"'
    opts = {
      'sort' => '"age": -1',
      'limit' => 10
    }
    query(input, opts)
    page.should have_table 'results'
    page.should have_selector("table#results tr", :count => 2)
    results = [
      JSON.parse('{ "_id": "51243e3fa588a7ea2216d63d", "name": "Anne", "sex": "Female", "age": 99}'),
      JSON.parse('{ "_id": "51243e3ca588a7ea2216d63a", "name": "Sue", "sex": "Female", "age": 27}')
    ]
    count = 0
    page.all('table#results tr').each do |row|
      result = JSON.parse(row.text)
      expect(result['_id']).to have_text results[count]['_id']
      expect(result['name']).to have_text results[count]['name']
      expect(result['sex']).to have_text results[count]['sex']
      expect(result['age']).to have_text results[count]['age']
      count += 1
    end
  end

  scenario "simple query with skip" do
    click_button 'skip'
    input = '"sex": "Female"'
    opts = {
      'skip' => '1',
      'limit' => 10
    }
    query(input, opts)
    page.should have_table 'results'
    page.should have_selector("table#results tr", :count => 1)
    result = JSON.parse(find('table#results a').text)
    expect(result['_id']).to have_text '51243e3fa588a7ea2216d63d'
    expect(result['name']).to have_text 'Anne'
    expect(result['sex']).to have_text 'Female'
    expect(result['age']).to have_text 99
  end

  scenario "empty query" do
    input = '"name": "Bobby"'
    opts = {'limit' => 10}
    query(input, opts)
    page.should have_table('results')
    page.should_not have_selector("table#results tr")
  end
end

