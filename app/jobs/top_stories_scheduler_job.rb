class TopStoriesSchedulerJob < ApplicationJob
  queue_as :default

  def perform
    hackernews_service = V1::HackernewsService.new
    limit = 15
    top_stories = hackernews_service.fetch_top_stories(limit)
   
    if ActionCable.server.present?
      begin
        ActionCable.server.broadcast("top_stories", top_stories)
      rescue Redis::CannotConnectError => e
        Rails.logger.warn "TopStoriesSchedulerJob: Redis connection failed, skipping broadcast: #{e.message}"
      rescue => e
        Rails.logger.warn "TopStoriesSchedulerJob: Broadcast failed, continuing: #{e.message}"
      end
    else
      Rails.logger.warn "TopStoriesSchedulerJob: ActionCable server not available for broadcast"
    end
    
  rescue => e
    Rails.logger.error "TopStoriesSchedulerJob failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
   
    raise e
  end
end
