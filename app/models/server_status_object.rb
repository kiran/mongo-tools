class ServerStatusObject
  include MongoMapper::Document
  connection(Mongo::Connection.new(Settings.stats.host, Settings.stats.port))
  set_database_name Settings.stats.db

  key :host, String
  key :timestamp, Time

  one :op_counters
  one :connections
  one :cursors

  def initialize
    MongoMapper.connection ||= Mongo::Connection.new(Settings.mongo.host, Settings.mongo.port)
    db = MongoMapper.connection[MongoMapper.connection.database_names[0]]
    stats = db.command( { serverStatus: 1 } )
    scrub!(stats)
    
    self.timestamp = stats["localTime"]
    self.host = stats["host"]
    self.op_counters = stats["opcounters"]
    self.connections = stats["connections"]
    self.cursors = stats["cursors"]

    self.save
  end

  private
  def scrub!(hash)
  # scrubs the keys of the hash to change offending "." and "$" characters
  q = [hash]
  while (!q.empty?)
    curr = q.pop()
    curr.keys.each do |key|
      # replace key with newkey by adding newkey and deleting old key
      newkey = key
      if key.include? "." or key.include? "$"
        newkey = newkey.gsub(".", ",")
        newkey.gsub!("$", "#")
        curr[newkey] = curr[key]
        curr.delete(key)
      end
      q << curr[newkey] if curr[newkey].is_a?(Hash)
    end
  end
  hash
end
end

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

class Connections
    include MongoMapper::EmbeddedDocument
    key :current, Integer
    key :available, Integer
    embedded_in :db_status_object
end

class Cursors
    include MongoMapper::EmbeddedDocument
    key :total_open, Integer
    key :client_cursors_size, Integer
    key :timedOut, Integer
    embedded_in :db_status_object
end

# format: 
# {
#   "host" : "hostname:port",
#   "opcounters" : {
#     "insert" : 4500,
#     "query" : 4832,
#     "update" : 2,
#     "delete" : 58,
#     "getmore" : 0,
#     "command" : 181
#   },
#   "connections" : {
#     "current" : 1,
#     "available" : 203
#   },
#   "cursors" : {
#     "totalOpen" : 0,
#     "clientCursors_size" : 0,
#     "timedOut" : 0
#   },
#   "localTime" : ISODate("2013-04-01T03:16:43.382Z"),
# }

