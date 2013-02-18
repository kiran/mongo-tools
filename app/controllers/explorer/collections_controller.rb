class Explorer::CollectionsController < ExplorerController
  def index
   # redirect_to explorer_collections_path(current_database_name)
redirect_to explorer_collection_document_path(current_database_name, current_collection_name)
  end
  
  def show
    @opts = {}
    #convert string to bool
    @explain = params[:explain] == "true"

    #parse out params
    @query = params[:query] ? Crack::JSON.parse("{#{params[:query]}}") : {}
    @opts[:fields] = params[:fields] ? Crack::JSON.parse("{#{params[:fields]}}") : {}
    @opts[:skip] = params[:skip].to_i
    @opts[:limit] = params[:limit].to_i
    @opts[:limit] = 25 unless (1..1000).include?(@opts[:limit])

    sort = params[:sort] ? Crack::JSON.parse("{#{params[:sort]}}") : {}
    sort.each_pair { |k,v| sort[k] = (v.to_i == -1) ? Mongo::DESCENDING : Mongo::ASCENDING }
    @opts[:sort] = sort
    
    @opts.delete_if { |k,v| v.kind_of?(Hash) && v.empty? }
    @opts[:fields].delete("_id") if @opts[:fields] && @opts[:fields].include?("_id")
    @results = current_collection.find(@query, @opts)
    render layout: !request.xhr?
  end

#POST
def create
    conn = MongoMapper.connection
    db = conn.db(current_database_name)
    db.create_collection(params[:coll])
 redirect_to explorer_collection_path(current_database_name, params[:coll])
end

#GET
  def new
    
  end
end
