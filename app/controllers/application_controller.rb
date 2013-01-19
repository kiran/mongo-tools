class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :current_collection_name, :current_database_name
  
  protected
    def current_database_name
      params[:controller] == "explorer" ? params[:id] : params[:explorer_id]
    end
    
    def current_collection_name
      params[:controller] == "explorer/collections" ? params[:id] : params[:collection_id]
    end
end
