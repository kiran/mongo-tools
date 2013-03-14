require "mongo"
include Mongo

require "stats_scheduler"

describe StatsScheduler, :statistics => true do
  before do
    test_db_name = "db_test_stats" # TODO: change this
    @stats_scheduler = StatsScheduler.new("localhost", 27017, "localhost", 27018, test_db_name)
    @read_client = MongoClient.new("localhost", 27017)

    @stats_client = MongoClient.new("localhost", 27018)
    @test_db = @stats_client[test_db_name]
    @test_db.drop_collection("db_stats")
    @test_db.drop_collection("srv_stats")
  end

  describe "#collect_opcounts" do
    before do
      @stats_scheduler.collect_opcounts
    end

    it "should insert 1 document into db stats collection" do
      dbs_coll = @test_db["db_stats"]
      dbs_coll.count.should eq(@read_client.database_names.size)
    end 

    it "should insert 1 document into server stats collection" do
      srv_coll = @test_db["srv_stats"]
      srv_coll.count.should eq(1)
    end

    before do
        # TODO insert 1 thing into a db
        @demo_db = @read_client["db_test_demo_stats"]
        @demo_db.drop_collection("demo_coll")
        @demo_coll = @demo_db["demo_coll"]
    end

    it "should count 1 insert on the server" do
      @demo_coll.insert({"test"=>"hi"})
      @stats_scheduler.collect_opcounts()
      # puts @demo_coll.find().sort({"$natural"=>1}).limit(2);
    end
    
    it "should count 1 insert on a specific database" #TODO
    it "should count 1 insert on the server database" #TODO
    it "should include all important/necessary stats" #TODO
  end

  describe "#scrub!" do
    it "should scrub out . and $ in first-level keys" do 
      test_bson = BSON::OrderedHash.new
      test_bson[ "a.a.a." ] = "aaa"
      test_bson[ "b$" ] = 9
      test_bson[ "c" ] = 1.033

      assert_bson = BSON::OrderedHash.new
      assert_bson[ "a,a,a," ] = "aaa"
      assert_bson[ "b#" ] = 9
      assert_bson[ "c" ] = 1.033

      @stats_scheduler.scrub!(test_bson)

      test_bson.should eql(assert_bson)
    end

    it "should scrub out . and $ in any level key" do 
      test_bson = BSON::OrderedHash.new
      test_bson[ "a.a.a." ] = "aaa"
      test_bson[ "b$" ] = 9
      test_bson[ "c" ] = 1.033

      inner_bson = BSON::OrderedHash.new
      inner_bson[ "a.a.a.." ] = "aaa"
      inner_bson[ "$$b$" ] = 9

      test_bson['inner.level'] = inner_bson

      assert_bson = BSON::OrderedHash.new
      assert_bson[ "a,a,a," ] = "aaa"
      assert_bson[ "b#" ] = 9
      assert_bson[ "c" ] = 1.033

      inner_bson2 = BSON::OrderedHash.new
      inner_bson2[ "a,a,a,," ] = "aaa"
      inner_bson2[ "##b#" ] = 9

      assert_bson['inner,level'] = inner_bson2

      @stats_scheduler.scrub!(test_bson)

      test_bson.should eql(assert_bson)
    end
  end
end

