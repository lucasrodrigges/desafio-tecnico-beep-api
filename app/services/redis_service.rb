require 'redis'
require 'json'
require 'securerandom'
require 'jwt'

class RedisService
  STORIES_CACHE_KEY = 'stories_cache'.freeze
  STORIES_CACHE_TTL = 3600

  def self.get_stories_cache
    redis = redis_instance
    cached = redis.get(STORIES_CACHE_KEY)
    cached ? JSON.parse(cached) : nil
  rescue => e
    Rails.logger.warn("[RedisService] Erro ao buscar stories do cache: #{e.message}")
    nil
  end

  def self.create_stories_cache(stories)
    redis = redis_instance
    redis.set(STORIES_CACHE_KEY, stories.to_json, ex: STORIES_CACHE_TTL)
  rescue => e
    Rails.logger.warn("[RedisService] Erro ao salvar stories no cache: #{e.message}")
    nil
  end

  def self.redis_instance
    @redis ||= Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379/0')
  end

  def self.rate_limit(key, limit, window: 60)
    count = redis_instance.incr(key)
    if count == 1
      redis_instance.expire(key, window)
    end
    count
  end

  def self.is_first_request(ip)
    key = "auth-secret-#{ip}"
    redis_instance.exists(key) == 0
  end

  def self.has_valid_authorization(ip, token)
    key = "auth-secret-#{ip}"
    value_in_redis = redis_instance.get(key)
    decoded_token = JWT.decode(token.gsub('Bearer ', ''), ENV['JWT_SECRET'], true, { algorithm: 'HS256' })
    decoded_token[0]['signature'] == value_in_redis
  end

  def self.create_first_request_signature(ip)
    key = "auth-secret-#{ip}"
    signature = SecureRandom.hex(32)
    
    payload = {
      signature: signature,
    }

    secret = ENV['JWT_SECRET']
    jwt_token = JWT.encode(payload, secret, 'HS256')

    redis_instance.set(key, signature, ex: 86400)

    "Bearer #{jwt_token}"
  rescue => e
    Rails.logger.warn("[RedisService] Erro ao criar assinatura de primeiro acesso: #{e.message}")
    nil
  end
end