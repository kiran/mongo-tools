class Explorer::DocumentsController < ExplorerController
  before_filter :require_edit_access, :except => [:index, :show]
  
  def index
    redirect_to explorer_collection(current_database_name, current_collection_name)
  end
  
  def show
  end
  
  def new
  end
end
