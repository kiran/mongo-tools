require 'rubygems'
require 'rufus/scheduler'  
require 'mongo'

include Mongo

unless ENV.has_key?('TRAVIS') || Rails.env.test?
	scheduler = Rufus::Scheduler.start_new

	# A capped collection has a max size and, optionally, a max number of records.
	# Old records get pushed out by new ones once the size or max num records is reached.

	# Connect to the db and set up capped collections for the statistics models
	db = MongoClient.new(Settings.stats.host, Settings.stats.port).db(Settings.stats.db)
	coll = db.create_collection('server_status_objects', :capped => true, :size => Settings.stats.size)

	# create a new server statistics object every n seconds
	scheduler.every(Settings.stats.frequency) do
	  ServerStatusObject.new
	end
end