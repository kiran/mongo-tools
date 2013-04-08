require 'date'

class ServerStatusesController < ApplicationController
  def index
  end
  def show
    from_string = params[:from]
    to_string   = params[:to]
    begin
      from_date = DateTime.strptime(from_string, '%Y%m%d%H%M%S')
    rescue
      from_date = nil
    end
    begin
      to_date = DateTime.strptime(to_string, '%Y%m%d%H%M%S')
    rescue
      to_date = DateTime.now
    end

    if from_date && from_date > to_date
      render :json => {"error" => "The from date must occur before the to date."}
      return
    end
    
    if from_date != nil
      results = ServerStatusObject.where(:timestamp => 
        { :$gte => Time.parse(from_date.to_s), :$lt => Time.parse(to_date.to_s) }).all
    else
      results = ServerStatusObject.where(:timestamp.lt => Time.parse(to_date.to_s)).all
    end
    
    # example
    # http://localhost:3000/server_status?from=20130403184944&to=20130406003444
    # "to" defaults to newest, "from" to oldest

    render :json => results.to_json
  end
end
