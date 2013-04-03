class OpCounters
    include MongoMapper::EmbeddedDocument
    key :insert, Integer
    key :query, Integer
    key :update, Integer
    key :delete, Integer
    key :get_more, Integer
    key :command, Integer
    embedded_in :db_status_object
end
