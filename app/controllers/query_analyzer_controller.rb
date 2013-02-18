require 'evaluator'
require 'json'

class QueryAnalyzerController < ApplicationController
	@@e = Evaluator.new 'localhost', 27017

  def index
    @query = params[:query]
    @collname = params[:collection_name]
    @evaluation_results = []
  	if @query && @collname
        @query = URI.unescape(@query)
        @collname = URI.unescape(@collname)
		@evaluation_results = @@e.evaluate_query(JSON.parse(@query), @collname)
	end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @evaluation_results }
    end
  end
end

