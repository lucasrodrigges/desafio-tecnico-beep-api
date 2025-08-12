class CacheTopStoriesJob < ApplicationJob
  queue_as :default

  def perform
    begin
      hackernews_service = V1::HackernewsService.new
      stories = hackernews_service.fetch_top_stories_cached
    rescue => e
      Rails.logger.error "[CacheTopStoriesJob] Error warming up cache: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end
  end
end
