class TopStoriesChannel < ApplicationCable::Channel
  def subscribed
    stream_from "top_stories"
  end

  def unsubscribed
  end
end
