if Rails.env.production?
  redis_url = ENV['UPSTASH_REDIS_URL']
  
  if redis_url.blank? && ENV['UPSTASH_REDIS_REST_URL'] && ENV['UPSTASH_REDIS_REST_TOKEN']
    rest_url = ENV['UPSTASH_REDIS_REST_URL']
    token = ENV['UPSTASH_REDIS_REST_TOKEN']
    uri = URI.parse(rest_url)
    redis_url = "redis://default:#{token}@#{uri.host}:#{uri.port || 6379}"
  end
  
  if redis_url
    ActionCable.server.config.cable = {
      adapter: 'redis',
      url: redis_url,
      channel_prefix: 'desafio_tecnico_beep_production'
    }
  end
end
