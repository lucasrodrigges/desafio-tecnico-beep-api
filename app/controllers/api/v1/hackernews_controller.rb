require 'net/http'
require 'json'

class Api::V1::HackernewsController < ApplicationController
  rescue_from StandardError do |e|
    Rails.logger.error "[HackernewsController ERROR] #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { error: INTERNAL_ERROR }, status: :internal_server_error
  end
  include Errors

  def search
    keyword = params[:query]
    if keyword.to_s.strip.empty?
      render json: { error: UNPROCESSABLE_ENTITY }, status: :unprocessable_entity
    else
      hackernews_service = V1::HackernewsService.new
      results = hackernews_service.search_stories(keyword)
      render json: results
    end
  end

  def top_stories
    top_stories = V1::HackernewsService.new.fetch_top_stories_cached
    top_stories.sort_by! { |story| -story['time'].to_i }
    render json: top_stories.first(15)
  end

  def relevant_comments
  hackernews_service = V1::HackernewsService.new
    story_id = params[:id]
    relevant_comments = hackernews_service.relevant_comments_for_story(story_id)
    render json: relevant_comments
  end
  
  def replies_at_comments
    ids = params[:ids].to_s.split(',').map(&:strip)
    if ids.empty?
      render json: { error: UNPROCESSABLE_ENTITY }, status: :unprocessable_entity
    else
      hackernews_service = V1::HackernewsService.new
      replies = hackernews_service.replies_at_comments(ids)
      render json: replies
    end
  end
end
