require 'date'

class OpcountsController < ApplicationController
  def index
  end
  def show
    db_name = params[:database_id]
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

    @record = {"from" => from_date, "to" => to_date, "dbname" => db_name}
    if from_date && from_date > to_date
      @record = {"error" => "The from date must occur before the to date."}
    end

    #TODO use the model to get the actual data, and return it here
    render :json => @record
  end
end
