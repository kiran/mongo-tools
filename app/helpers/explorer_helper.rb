module ExplorerHelper
  def all_databases
    @all_databases ||= MongoMapper.connection.database_names.sort.select { |d| can_read?(d) }
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
end