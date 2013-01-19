module ExplorerHelper
  def all_databases
    @all_databases ||= MongoMapper.connection.database_names.sort
  end
  
  def current_database
    current_database_name ? MongoMapper.connection[current_database_name] : nil
  end
  
  def current_collection
    current_collection_name ? current_database.collection(current_collection_name) : nil
  end
end
