class Connections
  include MongoMapper::EmbeddedDocument
  key :current, Integer
  key :available, Integer
  embedded_in :db_status_object
end
