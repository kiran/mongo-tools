require 'rubygems'
require 'rufus/scheduler'  
require 'mongo'
require 'stats_scheduler'

include Mongo

unless ENV.has_key?('TRAVIS')
	STATS_CONFIG = YAML.load_file("#{Rails.root}/config/stats.yml")[Rails.env]
	MONGO_CONFIG = YAML.load_file("#{Rails.root}/config/mongo.yml")[Rails.env]

	scheduler = Rufus::Scheduler.start_new
	stats_scheduler = StatsScheduler.new(MONGO_CONFIG["host"], 
	    MONGO_CONFIG["port"], STATS_CONFIG["stats_host"],
	    STATS_CONFIG["stats_port"], STATS_CONFIG["stats_server_db_name"])

	stats_scheduler.collect_opcounts
	scheduler.every(STATS_CONFIG["frequency"]) do
	  stats_scheduler.collect_opcounts
	end
end