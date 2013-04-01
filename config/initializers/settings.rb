require 'yaml'

config_path = File.expand_path("config/application.yml", Rails.root)

begin
  config = YAML.load_file(config_path)
rescue Errno::ENOENT
  raise "Make sure the settings file #{config_path} exists."
end

class DotHash < Hash
  def initialize(h)
    h.each do |k, v|
      self[k] = v.is_a?(Hash) ? DotHash.new(v) : v
    end
  end

  def method_missing(name, *args, &block)
    self[name.to_s]
  end
end

Settings = DotHash.new(config[Rails.env])

# Setup MongoMapper manually because we have our own config
# MongoMapper expects a hash with env => settings hash
MongoMapper.setup({ Rails.env => Settings.mongo }, Rails.env, :logger => Rails.logger)
