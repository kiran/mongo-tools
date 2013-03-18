require 'rubygems'
require 'rufus/scheduler'  
require 'mongo'

include Mongo

unless ENV.has_key?('TRAVIS')
	scheduler = Rufus::Scheduler.start_new

	# create a new server statistics object every n seconds
	scheduler.every(STATS_CONFIG["frequency"]) do
	  ServerStatusObject.new
	end
end