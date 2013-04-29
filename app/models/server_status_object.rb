class ServerStatusObject
  include MongoMapper::Document
  connection(MongoConnections.stats)
  set_database_name Settings.stats.database

  key :host, String
  key :timestamp, Time

  one :op_counters
  one :connections
  one :cursors

  def initialize
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

