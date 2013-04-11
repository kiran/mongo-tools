# Much of this will change with Mary and Kiran's stats API.

class MonitoringController < ApplicationController
  before_filter :init_conn

  def init_conn
    @viz_client = Mongo::MongoClient.new('localhost', 27017)
    @viz_db = @viz_client['tutorial']
    @viz_coll = @viz_db['users']
  end

  def index

  end

  def op_counts
    @oc = @viz_db.command({serverStatus: 1})["opcounters"]
    @op_count_arr = [@oc["insert"], @oc["query"], @oc["update"],
                     @oc["delete"], @oc["getmore"], @oc["command"]]
    render :json => @op_count_arr
  end

end
