require 'net/http'
require 'json'

class HackernewsController < ApplicationController
  def top_stories
    limit = params[:limit].to_i
    limit = 15 if limit <= 0
    top_ids = fetch_top_story_ids.first(limit)
    stories = top_ids.map { |id| fetch_story(id) }.compact
    stories.sort_by! { |story| -story['time'].to_i }
    render json: stories
  end

  private
  def fetch_top_story_ids
    url = URI('https://hacker-news.firebaseio.com/v0/topstories.json')
    response = Net::HTTP.get(url)
    JSON.parse(response)
  rescue
    []
  end
  
  def fetch_story(id)
    url = URI("https://hacker-news.firebaseio.com/v0/item/#{id}.json")
    response = Net::HTTP.get(url)
    JSON.parse(response)
  rescue
    nil
  end
end
