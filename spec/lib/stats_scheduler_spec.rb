require "mongo"
include Mongo

require "stats_scheduler"

describe StatsScheduler do
  before do
    test_db_name = "db_test_stats" # TODO: change this
    @stats_scheduler = StatsScheduler.new("localhost", 27017, 27017, test_db_name)
    @client = MongoClient.new("localhost", 27017)
    @test_db = @client[test_db_name]
    @test_db.drop_collection("db_stats")
    @test_db.drop_collection("srv_stats")
  end
  describe "#collect_statistics" do
    before do
      @stats_scheduler.collect_statistics()
    end

    it "should insert 1 document into db stats collection" do
      dbs_coll = @test_db["db_stats"]
      dbs_coll.count.should eq(@client.database_names.size)
    end

    it "should insert 1 document into server stats collection" do
      srv_coll = @test_db["srv_stats"]
      srv_coll.count.should eq(1)
    end

    before do
        # TODO insert 1 thing into a db
    end
    it "should count 1 insert on a specific database" #TODO
    it "should count 1 insert on the server database (really 2 right now)" #TODO
    it "should include all important/necesssary stats" #TODO

  end
end

