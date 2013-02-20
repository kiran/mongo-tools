require "mongo"
include Mongo

require "stats_scheduler"

describe StatsScheduler do
  before :all do
    @client = MongoClient.new("localhost", 27017)
    @tools_db = client['mongotools']
    @dbs_coll = tools_db['db_stats']
    @srv_coll = tools_db['srv_stats']
    @dbs_coll.find.each { |a|  puts a.inspect }
  end
end

