class TopStoriesChannel < ApplicationCable::Channel
  @@active_connections = Set.new

  def subscribed
    stream_from "top_stories"
    @@active_connections.add(self)
    Rails.logger.info "TopStoriesChannel: Connection added. Active connections: #{@@active_connections.size}"
  end

  def unsubscribed
    @@active_connections.delete(self)
    Rails.logger.info "TopStoriesChannel: Connection removed. Active connections: #{@@active_connections.size}"
  end

  def self.active_connections_count
    @@active_connections.size
  end

  def self.has_active_connections?
    @@active_connections.size > 0
  end
end
