# Setup MongoMapper manually because we have our own config
# MongoMapper expects a hash with env => settings hash
MongoMapper.setup({ Rails.env => Settings.mongo }, Rails.env, :logger => Rails.logger)
