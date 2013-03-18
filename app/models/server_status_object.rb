require 'stats_utils'

class ServerStatusObject
  include MongoMapper::Document
  STATS_CONFIG = YAML.load_file("#{Rails.root}/config/stats.yml")[Rails.env]
  connection(Mongo::Connection.new(STATS_CONFIG["stats_host"], STATS_CONFIG["stats_port"]))
  set_database_name STATS_CONFIG["stats_server_db_name"]

  key :host, String
  key :timestamp, Date

  one :op_counters
  one :connections
  one :cursors

  def initialize
    stats = MongoMapper.database.command( { serverStatus: 1 } )
    scrub!(stats)
    
    self.timestamp = stats["localTime"]
    self.host = stats["host"]
    self.op_counters = stats["opcounters"]
    self.connections = stats["connections"]
    self.cursors = stats["cursors"]

    self.save
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

