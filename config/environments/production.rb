require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  
  config.public_file_server.enabled = true
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }
  
  config.assume_ssl = false
  config.force_ssl = false
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  
  config.force_ssl = false if ENV['RAILWAY_ENVIRONMENT']
  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = false
  config.active_job.queue_adapter = :async
  config.active_job.queue_name_prefix = "beep_api_production"
  config.active_job.queue_name_delimiter = "_"
  config.active_job.default_timezone = 'America/Sao_Paulo'
  config.i18n.fallbacks = true
  config.secret_key_base = ENV['SECRET_KEY_BASE'] || Rails.application.credentials.secret_key_base
end
