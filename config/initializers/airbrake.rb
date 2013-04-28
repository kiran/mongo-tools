if Settings && Settings.airbrake && Settings.airbrake.api_key
  Airbrake.configure do |config|
    config.api_key = Settings.airbrake.api_key
    config.development_environments = [] if Settings.airbrake.log_development
  end
end