class TopStoriesSchedulerJob < ApplicationJob
  queue_as :default

  def perform
    hackernews_service = HackernewsService.new
    limit = 15
    top_stories = hackernews_service.fetch_top_story_ids.first(limit).map { |id| hackernews_service.fetch_story(id) }
    top_stories.sort_by! { |story| -story['time'].to_i }
    ActionCable.server.broadcast("top_stories", top_stories)
  end
end
