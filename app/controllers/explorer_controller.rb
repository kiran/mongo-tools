class ExplorerController < ApplicationController
  before_filter :check_mongo_blacklist
  
  def index
  end
  
  def show
  end
  
  protected
    def check_mongo_blacklist
      if current_database_name && !can_read_database?
        render "shared/blacklist"
        return
      end
      if current_collection_name && !can_read_collection?
        render "shared/collection_blacklist"
        return
      end
    end
    
    def require_edit_access
      if current_database_name && current_collection_name
        unless can_edit_collection?
          render "shared/collection_blacklist"
          return
        end
      elsif current_database_name
        unless can_edit_database?
          render "shared/blacklist"
          return
        end
      end
    end
end
