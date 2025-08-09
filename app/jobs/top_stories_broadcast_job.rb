class TopStoriesBroadcastJob < ApplicationJob
  queue_as :default

  def perform(top_stories)
    ActionCable.server.broadcast("top_stories", top_stories)
  end
end
