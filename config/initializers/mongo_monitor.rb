require 'rubygems'
require 'rufus/scheduler'
#require 'json'


class Query
	include MongoMapper::Document

	key :query, String
	key :first_done, Time
	key :last_done, Time
	key :number_of_times, Integer

end

history = Hash.new

scheduler = Rufus::Scheduler.start_new

scheduler.every '10m' do
	history.each do |key,value|
		query = Query.new(
				:query => key,
				:first_done => value[0],
				:last_done => value[1],
				:number_of_times => value[2]
			)
		query.save
	end
	history = Hash.new
end


prog = nil
t = Thread.new do
	IO.popen("./mongosniff --source NET lo") do |prog|
		prog.each do |line|
			if line[1..5]=='query' and line[11..26]!='replSetGetStatus'
				query = line[8..-27]
				puts query
				if history.has_key?(query)
					value = history[query]
					value[1] = Time.now.utc
					value[2] += 1
				else
					time_now = Time.now.utc
					value = [time_now, time_now, 1]
					history[query] = value
				end
				puts history
				#JSON.parse(line[8..27])
			end
		end
	end
end

#runs the program till the thread is alive
while t.alive?  do end
