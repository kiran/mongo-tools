class ExplorerController < ApplicationController
  before_filter :check_mongo_blacklist
  
  def index
  end
  
  def show
  end
  
  protected
    def check_mongo_blacklist
      if DATABASE_BLACKLIST.include? current_database_name
        render "shared/blacklist"
        return
      end
      if current_collection_name && COLLECTION_BLACKLIST.include?(current_collection_name) && current_document_id
        render "shared/collection_blacklist"
        return
      end
    end
end
