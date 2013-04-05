class Cursors
    include MongoMapper::EmbeddedDocument
    key :total_open, Integer
    key :client_cursors_size, Integer
    key :timedOut, Integer
    embedded_in :db_status_object
end