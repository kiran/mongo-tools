class Explorer::CollectionsController < ApplicationController
  def index
    redirect_to explorer_path(current_database_name)
  end
  
  def show
  end
end
