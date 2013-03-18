require 'spec_helper'
require "mongo"
include Mongo

describe ServerStatsObject, :statistics => true do
	before do
		# set up dummy test db
		# drop all collections on dummy
	end

	pending "insert 1 document into server stats collection"
	pending "should count 1 insert on the server"
end
