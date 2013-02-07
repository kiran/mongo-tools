class Explorer::DocumentsController < ExplorerController
  before_filter :require_edit_access, :except => [:index, :show]
  
  def index
    redirect_to explorer_collection_document_path(current_database_name, current_collection_name)
  end
  
  def show
  end
  
  def create
    coll = current_collection
    #If there's a JSON parsing problem, show the error to user
    #and allow them to try again.
    begin
      json = JSON.parse(params[:query])
      if json.has_key?('_id')
        json["_id"] = BSON::ObjectId(json["_id"])
      end
      coll.insert(json)
      redirect_to explorer_collection_path(current_database_name, current_collection_name)
    rescue JSON::ParserError => exc
      flash[:error] = "Error in parsing JSON"
      @query = params[:query]
      render :action => :new
    end
  end
  
  def destroy
    coll = current_collection
    coll.remove({'_id' => BSON::ObjectId(current_document_id)})
    redirect_to explorer_collection_path(current_database_name, current_collection_name)
  end
  
  def edit
    @query = current_document.to_json
  end
  
  def new
    new_id = BSON::ObjectId.new
    @query = "{_id: ObjectId(\""+new_id.to_s+"\")}"
  end
  
  def update
    coll = current_collection

    #If there's a JSON parsing problem, show the error to user
    #and allow them to try again.
    begin
      json = JSON.parse(params[:query])
      id = nil
      if json.has_key?('_id')
        id = BSON::ObjectId(json["_id"])
        json.delete("_id")
      else
        id = BSON::ObjectId(current_document_id)
      end
    
      coll.update({'_id' => id}, json)
      redirect_to explorer_collection_document_path(current_database_name, current_collection_name)
    rescue JSON::ParserError => exc
      flash[:error] = "Error in parsing JSON"
      @query = params[:query]
      render :action => :edit
    end
  end
end
