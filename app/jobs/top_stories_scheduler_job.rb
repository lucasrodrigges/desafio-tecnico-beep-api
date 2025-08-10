class TopStoriesSchedulerJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "TopStoriesSchedulerJob: Starting job execution"
   
    hackernews_service = V1::HackernewsService.new
    limit = 15
    top_stories = hackernews_service.fetch_top_stories(limit)
   
    Rails.logger.info "TopStoriesSchedulerJob: Fetched #{top_stories.size} valid stories"
    
    if ActionCable.server.present?
      ActionCable.server.broadcast("top_stories", top_stories)
   
      Rails.logger.info "TopStoriesSchedulerJob: Successfully broadcasted stories"
    else
   
      Rails.logger.warn "TopStoriesSchedulerJob: ActionCable server not available for broadcast"
    end
    
  rescue => e
    Rails.logger.error "TopStoriesSchedulerJob failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
   
    raise e
  end
end
