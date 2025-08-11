if Rails.env.production?
  redis_url = ENV['REDIS_URL']
  
  if redis_url.present?
    begin
      test_redis = Redis.new(url: redis_url, connect_timeout: 2, read_timeout: 2, write_timeout: 2)
      test_redis.ping
      test_redis.disconnect!
      
      ActionCable.server.config.cable = {
        adapter: 'redis',
        url: redis_url,
        channel_prefix: 'desafio_tecnico_beep_production'
      }
      
      Rails.logger.info "ActionCable configurado com Redis: #{redis_url.gsub(/\/\/.*@/, '//[REDACTED]@')}"
    rescue => e
      Rails.logger.warn "Não foi possível conectar ao Redis (#{e.message}), usando adapter async"
     
      ActionCable.server.config.cable = {
        adapter: 'async'
      }
    end
  else
    Rails.logger.warn "Nenhuma configuração Redis encontrada, usando adapter async"
    
    ActionCable.server.config.cable = {
      adapter: 'async'
    }
  end
end
