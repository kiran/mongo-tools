require 'spec_helper'

describe ExplorerController do


$test_db_name = ""
$test_db_name_duplicate =""
$blank_field_error = ""
$duplicate_database_error =""
$invalid_character_error = ""
$successful_copy_message =""
$successfull_add_message = ""
$test_db_name_duplicate = ""

# Create a databasename for insertion
# Maintain the error messages
before(:all) do
    
    test_db = Time.new
    test_db = test_db.inspect
    test_db = test_db.gsub(" ", "")
    test_db = test_db.gsub("-", "_")
    test_db = test_db.gsub(":", "")
    $test_db_name = "Test_database"+test_db
    $test_db_name_create_duplicate = $test_db_name +"createduplicate"
    $test_db_name_duplicate = $test_db_name +"copy"
    $test_db_create = $test_db_name+"create"

    $blank_field_error =  "Database name can't be empty."
    $duplicate_database_error =  "Database already exists in the system."
    $invalid_character_error =  "Database name can't have invalid characters."
    $successful_copy_message = "The database was copied successfully"
    $successfull_add_message = "The database was added successfully"
end

after(:all) do
  MongoMapper.connection.drop_database($test_db_name)
  MongoMapper.connection.drop_database($test_db_name_duplicate)
  MongoMapper.connection.drop_database($test_db_name+"create")
  MongoMapper.connection.drop_database($test_db_name_create_duplicate)
end


  describe "#create" do
    render_views
    context "with no parameters" do
      it "It should return and error" do
        visit explorer_path("")
        response.should be_success
        click_link "create-coll"
        fill_in "db" , :with=> ""
        click_button "Save Database"
        page.should have_selector("div",:text => $blank_field_error)
      end
    end

    context "with parameters" do 
      it "A database should be created"  do
        visit explorer_path("")
        response.should be_success
        click_link "create-coll"
        response.should be_success
        fill_in "db" , :with=> $test_db_create
        click_button "Save Database"
        response.should be_success

        # check if no error are displayed
        page.should_not have_selector("div",:text => $blank_field_error)
        page.should_not have_selector("div",:text => $invalid_character_error)
        page.should_not have_selector("div",:text => $duplicate_database_error)
        page.should have_selector("div",:text => $successfull_add_message)
      
        # check if the database has been created
        created = false
        database = MongoMapper.connection.database_names
        for db in database
          if db.casecmp($test_db_create) == 0
            created = true
            break
          end
        end
        created.should eq(true)
      end

      it "Error should be generated for incorrect format" do
        visit explorer_path("")
        response.should be_success
        click_link "create-coll"
        fill_in "db" , :with=> $test_db_name+".$ .."
        click_button "Save Database"
        page.should have_selector("div",:text => $invalid_character_error)
      end

      it "generate error for duplicate" do
        current_database  = Connection.new.db($test_db_name_create_duplicate)
        coll = current_database.collection('temp')   
        coll.remove

        visit explorer_path("")
        response.should be_success
        click_link "create-coll"
        fill_in "db" , :with=> $test_db_name_create_duplicate
        click_button "Save Database"
        response.should be_success
        page.should have_selector("div",:text => $duplicate_database_error)
      end
    end
  end


  describe "#destroy" do
    render_views

    it "Database should be deleted", js: true do
      visit explorer_path(:id=>$test_db_name)
      click_link "Delete Database"
      page.evaluate_script('window.confirm = function() { return true; }');
      response.should be_success

      #check if database is deleted
      deleted = true
      database = MongoMapper.connection.database_names
      for db in database
        if db.casecmp($test_db_name) == 0
          deleted = false
          break
        end
      end
      deleted.should eq(true)
    end
  end


  describe "#Edit" do
    render_views
    context "with no parameters" do
    
      it "It should return an error" do
        visit explorer_path($test_db_name)
        response.should be_success
        click_link "Copy Database"
        response.should be_success
        fill_in "db" , :with=> ""
        click_button "Save Database"
        page.should have_selector("div",:text => $blank_field_error)
      end
    end

    
    context "with parameters" do    
      it "Database should be copied" do 
        visit explorer_path($test_db_name)
        $test_db_name
        click_link "Copy Database"
        response.should be_success
        fill_in "db" , :with=> $test_db_name_duplicate
        click_button "Save Database"
        response.should be_success
        page.should_not have_selector("div",:text => $blank_field_error)
        page.should_not have_selector("div",:text => $invalid_character_error)
        page.should_not have_selector("div",:text => $duplicate_database_error)
        page.should have_selector("div",:text => $successful_copy_message)

        # check if database is deleted
        deleted = false
        # check if the database has been created
        database = MongoMapper.connection.database_names      
        for db in database
          if db.casecmp($test_db_name) == 0
            deleted = true
            break
          end
        end
        deleted.should eq(true)
      end

      it "It should give an error for invalid characters" do
        visit explorer_path($test_db_name)
        response.should be_success
        click_link "Copy Database"
        response.should be_success
        fill_in "db" , :with=> $test_db_name+". /"
        click_button "Save Database"
        page.should have_selector("div",:text => $invalid_character_error)
      end

      it "generate error for duplicate" do
        visit explorer_path($test_db_name)
        response.should be_success
        click_link "Copy Database"
        response.should be_success
        fill_in "db" , :with=> $test_db_name
        click_button "Save Database"
        page.should have_selector("div",:text => $duplicate_database_error)
      end


    end
  end

end