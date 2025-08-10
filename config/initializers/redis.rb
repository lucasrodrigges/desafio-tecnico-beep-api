if Rails.env.production?
  redis_url = ENV['UPSTASH_REDIS_REST_URL']
  redis_token = ENV['UPSTASH_REDIS_REST_TOKEN']
  
  if redis_url && redis_token
    redis_config = {
      url: redis_url,
      password: redis_token
    }
    
    ActionCable.server.config.cable = {
      adapter: 'redis',
      url: redis_url,
      password: redis_token,
      channel_prefix: 'desafio_tecnico_beep_production'
    }
  end
end
