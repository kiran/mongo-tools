require 'evaluator'
require 'json'

class QueryAnalyzerController < ApplicationController
	@@e = Evaluator.new 'localhost', 27017

  def index
  	@query = params[:query]
  	@evaluation_results = []
  	if @query
			@evaluation_results = @@e.evaluate_query(JSON.parse(URI.unescape(@query)), 'dbname.collname')
		end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @evaluation_results }
    end
  end
end

