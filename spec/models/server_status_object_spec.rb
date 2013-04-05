require 'spec_helper'
require "mongo"
include Mongo

describe ServerStatusObject, :statistics => true do
	before do
		# set up dummy test db
		# drop all collections on dummy
	end

	it "should insert 1 document into server stats collection" do
		ServerStatusObject.new
		# srv_coll.count.should eq(1)
	end

	it "should count 1 insert on the server" do
		ServerStatusObject.new
		# count # of inserts currently
		# @demo_coll.insert( {"test"=>"hi"} )
		ServerStatusObject.new
		# count # of inserts now
		# inserts.count.should eq(1)
	end
end
