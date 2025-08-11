require 'redis'
require 'json'
require 'securerandom'
require 'jwt'
require_relative './jwt_service.rb'

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
    return false if token.nil? || token.empty?
    
    key = "auth-secret-#{ip}"
    value_in_redis = redis_instance.get(key)
    return false if value_in_redis.nil?
    
    JWTService.decode(token.gsub('Bearer ', ''))['signature'] == value_in_redis
    
    rescue JWT::DecodeError, JWT::VerificationError => e
      Rails.logger.warn("[RedisService] JWT validation error: #{e.message}")
      false
    rescue => e
      Rails.logger.error("[RedisService] Unexpected error in has_valid_authorization: #{e.message}")
      false
  end

  def self.create_first_request_signature(ip)
    key = "auth-secret-#{ip}"
    signature = SecureRandom.hex(32)
    payload = {
      signature: signature,
    }
    jwt_token = JWTService.encode(payload)
    redis_instance.set(key, signature, ex: 86400)
    "Bearer #{jwt_token}"
  rescue => e
    Rails.logger.warn("[RedisService] Erro ao criar assinatura de primeiro acesso: #{e.message}")
    nil
  end
end