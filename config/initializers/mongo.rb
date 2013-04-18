def build_mongo_connection(opts)
  return nil unless opts
  options = opts.options ? opts.options.symbolize_keys : {}
  if opts.hosts
    Mongo::MongoReplicaSetClient.new(opts.hosts, options)
  else
    Mongo::MongoClient.new(opts.host, opts.port, options)
  end
end

# We're going to have a global connection pool for use accross the application
MongoConnections = DotHash.new({
  global: build_mongo_connection(Settings.mongo),
  stats: build_mongo_connection(Settings.stats),
})

# Setup MongoMapper manually because we have our own config
# MongoMapper expects a hash with env => settings hash
# MongoMapper.setup({ Rails.env => Settings.mongo }, Rails.env, :logger => Rails.logger)
MongoMapper.connection = MongoConnections.global
# Setup stuff for the default mongo DB
if Settings.mongo.database
  MongoMapper.database = Settings.mongo.database

  if Settings.mongo.username && Settings.mongo.password
    MongoConnections.global.add_auth(Settings.mongo.database, Settings.mongo.username, Settings.mongo.password)
  end
end
  
# store authentication data on the connection for stats if it exists
if MongoConnections.stats && Settings.stats.database && Settings.stats.username && Settings.stats.password
  MongoConnections.stats.add_auth(Settings.stats.database, Settings.stats.username, Settings.stats.password)
end
