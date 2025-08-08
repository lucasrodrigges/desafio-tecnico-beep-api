require 'net/http'
require 'json'
require_relative 'concerns/errors'
require_relative '../services/hackernews_service'

class HackernewsController < ApplicationController
  include Errors

  def search
    service = HackernewsService.new
    keyword = params[:q]
    results = service.search_stories(keyword)
    if keyword.to_s.strip.empty?
      render json: { error: UNPROCESSABLE_ENTITY }, status: :unprocessable_entity
    else
      render json: results
    end
  end

  def top_stories
    service = HackernewsService.new
    limit = params[:limit].to_i
    limit = 15 if limit <= 0
    top_stories = service.fetch_top_story_ids.first(limit).map { |id| service.fetch_story(id) }.compact
    top_stories.sort_by! { |story| -story['time'].to_i }
    render json: top_stories
  end

  def relevant_comments
    service = HackernewsService.new
    story_id = params[:id]
    relevant_comments = service.relevant_comments_for_story(story_id)
    if relevant_comments.any?
      render json: relevant_comments
    else
      render json: { error: NOT_FOUND }, status: :not_found
    end
  end
end
