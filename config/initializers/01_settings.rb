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
      self[k.to_s] = v.is_a?(Hash) ? DotHash.new(v) : v
    end
  end

  def method_missing(name, *args, &block)
    self[name.to_s]
  end
end

Settings = DotHash.new(config[Rails.env])
