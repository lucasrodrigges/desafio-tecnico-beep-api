require 'net/http'
require 'json'
require_relative '../../concerns/errors.rb'
require_relative '../../../services/v1/hackernews_service.rb'

class Api::V1::HackernewsController < ApplicationController
  include Errors

  def search
    hackernews_service = HackernewsService.new
    keyword = params[:query]
    results = hackernews_service.search_stories(keyword)
    if keyword.to_s.strip.empty?
      render json: { error: UNPROCESSABLE_ENTITY }, status: :unprocessable_entity
    else
      render json: results
    end
  end

  def top_stories
    limit = params[:limit].to_i
    limit = 15 if limit <= 0
    top_stories = HackernewsService.new.fetch_top_stories(limit)
    top_stories.sort_by! { |story| -story['time'].to_i }
    render json: top_stories
  end

  def relevant_comments
    hackernews_service = HackernewsService.new
    story_id = params[:id]
    relevant_comments = hackernews_service.relevant_comments_for_story(story_id)
    if relevant_comments.any?
      render json: relevant_comments
    else
      render json: { error: NOT_FOUND }, status: :not_found
    end
  end
end
