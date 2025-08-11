class TopStoriesSchedulerJob < ApplicationJob
  queue_as :default

  def perform
    puts.info "TopStoriesSchedulerJob: Starting job execution"
   
    hackernews_service = V1::HackernewsService.new
    limit = 15
    top_stories = hackernews_service.fetch_top_stories(limit)
   
    puts.info "TopStoriesSchedulerJob: Fetched #{top_stories.size} valid stories"
    
    if ActionCable.server.present?
      begin
        ActionCable.server.broadcast("top_stories", top_stories)
        puts.info "TopStoriesSchedulerJob: Successfully broadcasted stories"
      rescue Redis::CannotConnectError => e
        puts.warn "TopStoriesSchedulerJob: Redis connection failed, skipping broadcast: #{e.message}"
      rescue => e
        puts.warn "TopStoriesSchedulerJob: Broadcast failed, continuing: #{e.message}"
      end
    else
      puts.warn "TopStoriesSchedulerJob: ActionCable server not available for broadcast"
    end
    
  rescue => e
    puts.error "TopStoriesSchedulerJob failed: #{e.message}"
    puts.error e.backtrace.join("\n")
   
    raise e
  end
end
