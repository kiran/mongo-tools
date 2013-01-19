class Explorer::DocumentsController < ExplorerController
  def index
    redirect_to explorer_collection(current_database_name, current_collection_name)
  end
  
  def show
  end
end
