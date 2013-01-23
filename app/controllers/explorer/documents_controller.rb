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
    coll.insert(json)
    redirect_to explorer_collection_path(current_database_name, current_collection_name)
  end
  
  def new
    new_id = BSON::ObjectId.new
    @query = "{_id: ObjectId(\""+new_id+"\")}"
  end
end
