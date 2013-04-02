require 'rubygems'
require 'rufus/scheduler'  
require 'mongo'

include Mongo

unless ENV.has_key?('TRAVIS')
	scheduler = Rufus::Scheduler.start_new

	STATS_CONFIG = YAML.load_file("#{Rails.root}/config/stats.yml")[Rails.env]

	# A capped collection has a max size and, optionally, a max number of records.
	# Old records get pushed out by new ones once the size or max num records is reached.

	# Connect to the db and set up capped collections for the statistics models
	db = MongoClient.new(STATS_CONFIG['stats_host'], STATS_CONFIG['stats_port']).db(STATS_CONFIG['stats_db_name'])
	coll = db.create_collection('server_status_objects', :capped => true, :size => STATS_CONFIG['size'])

	# create a new server statistics object every n seconds
	scheduler.every(STATS_CONFIG["frequency"]) do
	  ServerStatusObject.new
	end
end