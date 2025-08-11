require 'redis'
require 'json'
require 'securerandom'
require 'jwt'
require 'digest'
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

  def self.generate_device_key(ip, user_agent, device_id = nil)
    if device_id.present?
      fingerprint = device_id
    else
      user_agent_clean = (user_agent || 'unknown').strip
      raw_fingerprint = "#{ip}-#{user_agent_clean}"
      fingerprint = Digest::SHA256.hexdigest(raw_fingerprint)[0, 16]
    end
    "auth-secret-#{fingerprint}"
  end

  def self.is_first_request(ip, user_agent, device_id = nil)
    key = generate_device_key(ip, user_agent, device_id)
    redis_instance.exists(key) == 0
  end

  def self.has_valid_authorization(ip, user_agent, token, device_id = nil)
    return false if token.nil? || token.empty?
    
    decoded_token = JwtService.decode(token.gsub('Bearer ', ''))
    return false if decoded_token.nil? || !decoded_token.is_a?(Hash)
    
    signature = decoded_token['signature']
    device_fingerprint = decoded_token['device_fingerprint']
    return false if signature.nil? || signature.empty?
    
    key = generate_device_key(ip, user_agent, device_id)
    value_in_redis = redis_instance.get(key)
    
    return false if value_in_redis.nil?

    begin
      stored_data = JSON.parse(value_in_redis)
      stored_data['signature'] == signature && stored_data['device_fingerprint'] == device_fingerprint
    rescue JSON::ParserError
      value_in_redis == signature
    end

    rescue JWT::DecodeError, JWT::VerificationError => e
      Rails.logger.warn("[RedisService] JWT validation error: #{e.message}")
      false
    rescue => e
      Rails.logger.error("[RedisService] Unexpected error in has_valid_authorization: #{e.message}")
      false
  end

  def self.create_first_request_signature(ip, user_agent, device_id = nil)
    signature = SecureRandom.uuid
    
    if device_id.nil?
      device_id = SecureRandom.uuid
    end
    
    device_fingerprint = device_id
    key = generate_device_key(ip, user_agent, device_id)
    
    redis_data = {
      signature: signature,
      device_fingerprint: device_fingerprint,
      ip: ip,
      user_agent: user_agent,
      created_at: Time.current.iso8601
    }
    
    jwt_payload = {
      signature: signature,
      device_fingerprint: device_fingerprint,
      device_id: device_id
    }
    
    jwt_token = JwtService.encode(jwt_payload)
    redis_instance.set(key, redis_data.to_json, ex: 86400)
    
    {
      token: "Bearer #{jwt_token}",
      device_id: device_id
    }
  rescue => e
    Rails.logger.warn("[RedisService] Erro ao criar assinatura de primeiro acesso: #{e.message}")
    nil
  end
end