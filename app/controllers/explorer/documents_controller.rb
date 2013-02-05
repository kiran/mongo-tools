class Explorer::DocumentsController < ExplorerController
  before_filter :require_edit_access, :except => [:index, :show]
  
  def index
    redirect_to explorer_collection_document_path(current_database_name, current_collection_name)
  end
  
  def show
  end
  
  def create
    conn = MongoMapper.connection
    db = conn.db(current_database_name)
    coll = db.collection(current_collection_name)
    json = JSON.parse(params[:query])
    if json.has_key?('_id')
      json["_id"] = BSON::ObjectId(json["_id"])
    end
    coll.insert(json)
    redirect_to explorer_collection_path(current_database_name, current_collection_name)
  end
  
  def destroy
    conn = MongoMapper.connection
    db = conn.db(current_database_name)
    coll = db.collection(current_collection_name)
    coll.remove({'_id' => BSON::ObjectId(current_document_id)})
    redirect_to explorer_collection_path(current_database_name, current_collection_name)
  end
  
  def new
    new_id = BSON::ObjectId.new
    @query = "{_id: ObjectId(\""+new_id.to_s+"\")}"
  end
  
  def update
    conn = MongoMapper.connection
    db = conn.db(current_database_name)
    coll = db.collection(current_collection_name)
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
  end
end
