require 'net/http'
require 'json'

module V1
  class HackernewsService
    HACKERNEWS_API_BASE_URL = "https://hacker-news.firebaseio.com/v0"

    def fetch_top_stories(limit = 15)
      ids = fetch_top_story_ids.first(limit)
      stories = []
      threads = ids.map do |id|
        Thread.new do
          story = fetch_story(id)
          stories << story if story
        end
      end
      threads.each(&:join)
      stories
    end

    def fetch_top_story_ids
      url = URI("#{HACKERNEWS_API_BASE_URL}/topstories.json")
      response = Net::HTTP.get(url)
      result = JSON.parse(response)
      result
    rescue => e
      Rails.logger.error "[HackernewsService] fetch_top_story_ids error: #{e.message}"
      []
    end

    def fetch_latest_story_ids
      url = URI("#{HACKERNEWS_API_BASE_URL}/newstories.json")
      response = Net::HTTP.get(url)
      result = JSON.parse(response)
      result
    rescue => e
      Rails.logger.error "[HackernewsService] fetch_latest_story_ids error: #{e.message}"
      []
    end

    def fetch_story(id)
      url = URI("#{HACKERNEWS_API_BASE_URL}/item/#{id}.json")
      response = Net::HTTP.get(url)
      result = JSON.parse(response)
      result
    rescue => e
      Rails.logger.error "[HackernewsService] fetch_story error for id=#{id}: #{e.message}"
      nil
    end

    def fetch_comment(id)
      url = URI("#{HACKERNEWS_API_BASE_URL}/item/#{id}.json")
      response = Net::HTTP.get(url)
      result = JSON.parse(response)
      result
    rescue => e
      Rails.logger.error "[HackernewsService] fetch_comment error for id=#{id}: #{e.message}"
      nil
    end

    def relevant_comments_for_story(story_id, min_words: 20)
      story = fetch_story(story_id)
      return [] unless story && story['kids']
      comment_ids = story['kids']
      comments = []
      threads = comment_ids.map do |comment_id|
        Thread.new do
          comment = fetch_comment(comment_id)
          comments << comment if comment
        end
      end
      threads.each(&:join)
      filtered = comments.select { |c| c['text'] && c['text'].split.size > min_words }
      filtered.sort_by { |c| -(c['score'] || 0) }
    end

    def replies_at_comments(ids)
      comments = []
      threads = ids.map do |id|
        Thread.new do
          comment = fetch_comment(id)
          comments << comment if comment && comment['text'] && comment['by']
        end
      end
      threads.each(&:join)
      comments
    end

    def search_stories(keyword, max_ids: 500, limit: 10)
      keyword = keyword.to_s.strip.downcase
      return [] if keyword.empty?

      stories = RedisService.get_stories_cache

      unless stories
        latest_ids = fetch_latest_story_ids.first(max_ids)
        stories = []
        threads = latest_ids.map do |id|
          Thread.new do
            story = fetch_story(id)
            stories << story if story
          end
        end
        threads.each(&:join)
        RedisService.create_stories_cache(stories)
      end

      filtered = stories.select do |story|
        story['title']&.downcase&.include?(keyword) ||
        story['text']&.downcase&.include?(keyword) ||
        story['by']&.downcase&.include?(keyword)
      end
      filtered.sort_by { |story| -story['time'].to_i }.first(limit)
    end
  end
end
