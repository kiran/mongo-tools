require 'yaml'

# Load the statistics YAML file
CONFIG = YAML.load_file("#{Rails.root}/config/stats.yml")[Rails.env]

namespace :setup do
	# set up the path and logpath
	directory CONFIG["path"]
	directory CONFIG["logpath"]

	desc "set up mongodb server on this computer for monitoring data"
	task :server do
		puts "setting up the secondary stats server"
		sh "mongod --dbpath #{CONFIG['path']} --port #{CONFIG['stats_port']} --fork --logpath #{CONFIG['logpath']}"
	end
end