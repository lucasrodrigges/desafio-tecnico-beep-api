require 'net/http'
require 'json'

class Api::V1::HackernewsController < ApplicationController
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
    limit = params[:limit].to_i
    limit = 15 if limit <= 0
  top_stories = V1::HackernewsService.new.fetch_top_stories(limit)
    top_stories.sort_by! { |story| -story['time'].to_i }
    render json: top_stories
  end

  def relevant_comments
  hackernews_service = V1::HackernewsService.new
    story_id = params[:id]
    relevant_comments = hackernews_service.relevant_comments_for_story(story_id)
    if relevant_comments.any?
      render json: relevant_comments
    else
      render json: { error: NOT_FOUND }, status: :not_found
    end
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
