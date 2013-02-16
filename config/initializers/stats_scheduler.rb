require 'rubygems'
require 'rufus/scheduler'  
require 'mongo'

include Mongo

scheduler = Rufus::Scheduler.start_new
client = MongoClient.new("localhost", 27017)

tools_db = client['mongotools']
dbs_coll = tools_db['db_stats']
srv_coll = tools_db['srv_stats']

scheduler.every("2s") do
  dbs = client.database_names
  stats = client[dbs[0]].command({serverStatus: 1})
  stats.delete("locks")
  time = stats["localTime"]

  doc = {"time" => time, "stats" => stats}

  srv_coll.insert(doc)

  dbs.each do |db_name|
    db = client[db_name]
    info = db.command({dbStats: 1, scale: 1024})

    doc = {"time" => time, "name"=> db_name, "stats" => info}
    dbs_coll.insert(doc)
  end
end