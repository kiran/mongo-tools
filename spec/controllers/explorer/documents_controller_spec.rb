require 'spec_helper'

describe Explorer::DocumentsController do
  
  before(:each) do
    #Insert some data for the test
    db = MongoMapper.connection['mongotools_test']
    coll = db.collection('foo')
    coll.insert({'_id'=> BSON::ObjectId('510571677af4a25da80355c8'), 'name'=> 'Bob'})
  end
  
  after(:each) do
    #Remove some data that was used to test.
    db = MongoMapper.connection['mongotools_test']
    coll = db.collection('foo')
    coll.remove
  end

  describe "Showing a Document" do
    it "A document that exist should display it's information" do
      get 'show', {:explorer_id => 'mongotools_test', :collection_id => 'foo', :id => '510571677af4a25da80355c8'}
      response.should be_success
      flash[:error].should be_nil
      assigns(:doc).should_not be_nil
    end

    it "A document that doesn't exist should an error message" do
      get 'show', {:explorer_id => 'mongotools_test', :collection_id => 'foo', :id => '510571677af4a25da80355c7'}
      response.should be_success
      flash[:error].should_not be_nil
      assigns(:doc).should be_nil
    end
  end
  
  describe "New Documents" do
    it "should display a page to type new documents into" do
      get 'new', {:explorer_id => "mongotools_test", :collection_id => "foo"}
      response.should be_success
      assigns(:query).should_not be_nil
    end
    
    it "invalid JSON should show an error message" do
      post 'create', {:explorer_id => "mongotools_test", :collection_id => "foo", :query => "{blah 1}"}
      response.should be_success
      flash[:error].should_not be_nil
    end
    
    it "no query sent should show an error message" do
      post 'create', {:explorer_id => "mongotools_test", :collection_id => "foo"}
      response.should be_success
      flash[:error].should_not be_nil
    end
    
    it "valid JSON should save correctly" do
      post 'create', {:explorer_id => "mongotools_test", :collection_id => "foo", :query => "{\"name\": \"Daddy\"}"}
      response.should be_redirect
      flash[:error].should be_nil
      db = MongoMapper.connection['mongotools_test']
      coll = db.collection('foo')
      doc = coll.find_one({"name"=> "Daddy"})
      doc.should_not be_nil
    end
  end
  
  describe "Edit Documents" do
    it "should display a page to edit new documents into" do
      get 'edit', {:explorer_id => "mongotools_test", :collection_id => "foo", :id => '510571677af4a25da80355c8'}
      response.should be_success
      assigns(:query).should_not be_nil
    end
    
    it "invalid JSON should show an error message" do
      post 'update', {:explorer_id => "mongotools_test", :collection_id => "foo", :id => '510571677af4a25da80355c8', :query => "{blah 1}"}
      response.should be_success
      flash[:error].should_not be_nil
    end
    
    it "valid JSON should save correctly" do
      post 'update', {:explorer_id => "mongotools_test", :collection_id => "foo", :id => '510571677af4a25da80355c8', :query => "{\"_id\": \"510571677af4a25da80355c8\", \"name\": \"Big Daddy\"}"}
      response.should be_redirect
      flash[:error].should be_nil
      db = MongoMapper.connection['mongotools_test']
      coll = db.collection('foo')
      doc = coll.find_one({"name"=> "Big Daddy"})
      doc.should_not be_nil
    end
    
    it "missing _id should get from URL" do
      post 'update', {:explorer_id => "mongotools_test", :collection_id => "foo", :id => '510571677af4a25da80355c8', :query => "{\"name\": \"Bigger Daddy\"}"}
      response.should be_redirect
      flash[:error].should be_nil
      db = MongoMapper.connection['mongotools_test']
      coll = db.collection('foo')
      doc = coll.find_one({"name"=> "Bigger Daddy"})
      doc.should_not be_nil
      doc['_id'].should == BSON::ObjectId('510571677af4a25da80355c8')
    end
  end
  
  describe "Delete Documents" do
    it "Deleting a valid document should work" do
      db = MongoMapper.connection['mongotools_test']
      coll = db.collection('foo')
      doc = coll.find_one({'_id' => BSON::ObjectId('510571677af4a25da80355c8')})
      doc.should_not be_nil
      delete 'destroy', {:explorer_id => "mongotools_test", :collection_id => "foo", :id => '510571677af4a25da80355c8'}
      doc = coll.find_one({'_id' => BSON::ObjectId('510571677af4a25da80355c8')})
      doc.should be_nil
      response.should be_redirect
    end
  end

end
