require 'spec_helper'

describe Explorer::DocumentsController do
  #Gets the DB name, so it's not hardcoded
  $test_db_name = ""
  let(:test_db_name) do
    $test_db_name = MongoMapper.database.name
  end
  
  #Sets the collection name, so it's not hardcoded
  $test_collection_name = ""
  let(:test_collection_name) do
    $test_collection_name = "foo"
  end
  
  before(:each) do
    #Insert some data for the test
    coll = MongoMapper.database.collection(test_collection_name)
    coll.insert({'_id'=> BSON::ObjectId('510571677af4a25da80355c8'), 'name'=> 'Bob'})
  end
  
  after(:each) do
    MongoMapper.database.collections.each do |coll| 
      coll.remove 
    end 
  end

  describe "Showing a Document" do
    it "A document that exist should display it's information" do
      get 'show', {:explorer_id => test_db_name, :collection_id => test_collection_name, :id => '510571677af4a25da80355c8'}
      response.should be_success
      flash[:error].should be_nil
      assigns(:doc).should_not be_nil
    end

    it "A document that doesn't exist should an error message" do
      get 'show', {:explorer_id => test_db_name, :collection_id => test_collection_name, :id => '510571677af4a25da80355c7'}
      response.should be_success
      flash[:error].should_not be_nil
      assigns(:doc).should be_nil
    end
  end
  
  describe "New Documents" do
    it "should display a page to type new documents into" do
      get 'new', {:explorer_id => test_db_name, :collection_id => test_collection_name}
      response.should be_success
      assigns(:query).should_not be_nil
    end
    
    it "invalid JSON should show an error message" do
      post 'create', {:explorer_id => test_db_name, :collection_id => test_collection_name, :query => "{blah 1}"}
      response.should be_success
      flash[:error].should_not be_nil
    end
    
    it "no query sent should show an error message" do
      post 'create', {:explorer_id => test_db_name, :collection_id => test_collection_name}
      response.should be_success
      flash[:error].should_not be_nil
    end
    
    it "valid JSON should save correctly" do
      post 'create', {:explorer_id => test_db_name, :collection_id => test_collection_name, :query => "{\"name\": \"Daddy\"}"}
      response.should be_redirect
      flash[:error].should be_nil
      flash[:info].should_not be_nil
      coll = MongoMapper.database.collection(test_collection_name)
      doc = coll.find_one({"name"=> "Daddy"})
      doc.should_not be_nil
    end
  end
  
  describe "Edit Documents" do
    it "should display a page to edit new documents into" do
      get 'edit', {:explorer_id => test_db_name, :collection_id => test_collection_name, :id => '510571677af4a25da80355c8'}
      response.should be_success
      assigns(:query).should_not be_nil
    end
    
    it "invalid JSON should show an error message" do
      post 'update', {:explorer_id => test_db_name, :collection_id => test_collection_name, :id => '510571677af4a25da80355c8', :query => "{blah 1}"}
      response.should be_success
      flash[:error].should_not be_nil
    end
    
    it "valid JSON should save correctly" do
      post 'update', {:explorer_id => test_db_name, :collection_id => test_collection_name, :id => '510571677af4a25da80355c8', :query => "{\"_id\": \"510571677af4a25da80355c8\", \"name\": \"Big Daddy\"}"}
      response.should be_redirect
      flash[:error].should be_nil
      flash[:info].should_not be_nil
      coll = MongoMapper.database.collection(test_collection_name)
      doc = coll.find_one({"name"=> "Big Daddy"})
      doc.should_not be_nil
    end
    
    it "missing _id should get from URL" do
      post 'update', {:explorer_id => test_db_name, :collection_id => test_collection_name, :id => '510571677af4a25da80355c8', :query => "{\"name\": \"Bigger Daddy\"}"}
      response.should be_redirect
      flash[:error].should be_nil
      coll = MongoMapper.database.collection(test_collection_name)
      doc = coll.find_one({"name"=> "Bigger Daddy"})
      doc.should_not be_nil
      doc['_id'].should == BSON::ObjectId('510571677af4a25da80355c8')
    end
  end
  
  describe "Delete Documents" do
    it "Deleting a valid document should work" do
      coll = MongoMapper.database.collection(test_collection_name)
      doc = coll.find_one({'_id' => BSON::ObjectId('510571677af4a25da80355c8')})
      doc.should_not be_nil
      delete 'destroy', {:explorer_id => test_db_name, :collection_id => test_collection_name, :id => '510571677af4a25da80355c8'}
      doc = coll.find_one({'_id' => BSON::ObjectId('510571677af4a25da80355c8')})
      flash[:error].should be_nil
      flash[:info].should_not be_nil
      doc.should be_nil
      response.should be_redirect
    end
  end

end
