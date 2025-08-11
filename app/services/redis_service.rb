require 'redis'
require 'json'

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
end