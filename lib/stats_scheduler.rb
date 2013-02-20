require 'rubygems'
require 'mongo'

include Mongo

class StatsScheduler
  def initialize (server, host, db_name)
    @client = MongoClient.new(server, host)
    @tools_db = @client[db_name]

    @dbs_coll = @tools_db['db_stats']
    @srv_coll = @tools_db['srv_stats']
  end

  def collect_statistics
    dbs = @client.database_names
    stats = @client[dbs[0]].command({serverStatus: 1})
    stats.delete("locks")
    time = stats["localTime"]

    doc = {"time" => time, "stats" => stats}

    @srv_coll.insert(doc)

    dbs.each do |db_name|
      db = @client[db_name]
      info = db.command({dbStats: 1, scale: 1024})

      doc = {"time" => time, "name"=> db_name, "stats" => info}
      @dbs_coll.insert(doc)
    end
  end
end

