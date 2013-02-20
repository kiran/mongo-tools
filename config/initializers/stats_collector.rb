require 'rubygems'
require 'rufus/scheduler'  
require 'mongo'
require 'stats_scheduler'

include Mongo

scheduler = Rufus::Scheduler.start_new
stats_scheduler = StatsScheduler.new("localhost", 27017, "db_stats")
scheduler.every("2s") do
  stats_scheduler.collect_statistics
end
