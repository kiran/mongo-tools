class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :can_read?, :can_edit?, :can_edit_collection?, :can_edit_database?, :can_read_collection?,
                :can_read_database?, :current_collection_name, :current_database_name, :current_document_id,
                :current_database, :current_collection, :current_document
  
  protected
    def current_database_name
      params[:controller] == "explorer" ? params[:id] : params[:explorer_id]
    end
    
    def current_collection_name
      current_database_name && params[:controller] == "explorer/collections" ? params[:id] : params[:collection_id]
    end
    
    def current_document_id
      current_collection_name && params[:controller] == "explorer/documents" ? params[:id] : nil
    end
    
    def current_database
      @current_database ||= current_database_name ? MongoMapper.connection[current_database_name] : nil
    end
  
    def current_collection
      @current_collection ||= current_collection_name ? current_database.collection(current_collection_name) : nil
    end
  
    def current_document
      @current_document ||= current_document_id ? current_collection.find_one(BSON::ObjectId(current_document_id)) : nil
    end

    def can_read?(db = nil, coll = nil)
      db ||= current_database_name
      coll ||= current_collection_name
      return db && coll ? can_read_collection?(db, coll) : can_read_database?(db)
    end
    
    def can_edit?(db = nil, coll = nil)
      db ||= current_database_name
      coll ||= current_collection_name
      return db && coll ? can_edit_collection?(db, coll) : can_read_database?(db)
    end
    
    def can_read_database?(db = nil)
      db ||= current_database_name
      raise Exception, "Possible bug with DB security" unless db
      !DATABASE_BLACKLIST.include?(db)
    end
    
    def can_edit_database?(db = nil)
      db ||= current_database_name
      raise Exception, "Possible bug with DB security" unless db
      can_read_database?(db) && !DATABASE_READ_ONLY.include?(db)
    end
    
    def can_read_collection?(db = nil, coll = nil)
      db ||= current_database_name
      coll ||= current_collection_name
      raise Exception, "Possible bug with DB security" unless db && coll
      can_read_database?(db) && !COLLECTION_BLACKLIST.include?(coll)
    end
    
    def can_edit_collection?(db = nil, coll = nil)
      db ||= current_database_name
      coll ||= current_collection_name
      raise Exception, "Possible bug with DB security" unless db && coll
      can_edit_database?(db) && can_read_collection?(db, coll) && !COLLECTION_READ_ONLY.include?(coll)      
    end
end
