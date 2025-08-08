HACKERNEWS_API_BASE_URL = 'https://hacker-news.firebaseio.com/v0'
require 'net/http'
require 'json'
require_relative 'concerns/errors'

class HackernewsController < ApplicationController
  include Errors

  def search
    max_ids_to_fetch = 30
    keyword = params[:q].to_s.strip.downcase
    return render json: { error: UNPROCESSABLE_ENTITY }, status: :unprocessable_entity if keyword.empty?

    latest_ids = fetch_latest_story_ids.first(max_ids_to_fetch)
    stories = latest_ids.map { |id| fetch_story(id) }.compact
    filtered = stories.select do |story|
      story['title']&.downcase&.include?(keyword) ||
      story['text']&.downcase&.include?(keyword) ||
      story['by']&.downcase&.include?(keyword)
    end
    filtered.sort_by! { |story| -story['time'].to_i }
    render json: filtered.first(10)
  end

  def top_stories
    limit = params[:limit].to_i
    limit = 15 if limit <= 0
    top_ids = fetch_top_story_ids.first(limit)
    stories = top_ids.map { |id| fetch_story(id) }.compact
    stories.sort_by! { |story| -story['time'].to_i }
    render json: stories
  end

  def relevant_comments
    max_length = 20
    story = fetch_story(params[:id])
    if story && story['kids']
      comments = story['kids'].map { |comment_id| fetch_comment(comment_id) }.compact
      relevant_comments = comments.select do |current_comment|
        current_comment['text'] && current_comment['text'].split.size > max_length
      end
      relevant_comments.sort_by! { |current_comment| -(current_comment['score'] || 0) }
      render json: relevant_comments
    else
      render json: { error: NOT_FOUND }, status: :not_found
    end
  end

  private

  def fetch_top_story_ids
  url = URI("#{HACKERNEWS_API_BASE_URL}/topstories.json")
    response = Net::HTTP.get(url)
    JSON.parse(response)
  rescue
    []
  end

  def fetch_latest_story_ids
  url = URI("#{HACKERNEWS_API_BASE_URL}/newstories.json")
    response = Net::HTTP.get(url)
    JSON.parse(response)
  rescue
    []
  end
  
  def fetch_story(id)
  url = URI("#{HACKERNEWS_API_BASE_URL}/item/#{id}.json")
    response = Net::HTTP.get(url)
    JSON.parse(response)
  rescue
    nil
  end

  def fetch_comment(id)
  url = URI("#{HACKERNEWS_API_BASE_URL}/item/#{id}.json")
    response = Net::HTTP.get(url)
    JSON.parse(response)
  rescue
    nil
  end
end
