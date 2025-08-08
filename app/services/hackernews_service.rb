# frozen_string_literal: true
require 'net/http'
require 'json'

class HackernewsService
  HACKERNEWS_API_BASE_URL = 'https://hacker-news.firebaseio.com/v0'

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

  def relevant_comments_for_story(story_id, min_words: 20)
    story = fetch_story(story_id)
    return [] unless story && story['kids']
    comments = story['kids'].map { |comment_id| fetch_comment(comment_id) }.compact
    comments.select { |c| c['text'] && c['text'].split.size > min_words }
            .sort_by { |c| -(c['score'] || 0) }
  end

  def search_stories(keyword, max_ids: 30, limit: 10)
    keyword = keyword.to_s.strip.downcase
    return [] if keyword.empty?
    latest_ids = fetch_latest_story_ids.first(max_ids)
    stories = latest_ids.map { |id| fetch_story(id) }.compact
    filtered = stories.select do |story|
      story['title']&.downcase&.include?(keyword) ||
      story['text']&.downcase&.include?(keyword) ||
      story['by']&.downcase&.include?(keyword)
    end
    filtered.sort_by { |story| -story['time'].to_i }.first(limit)
  end
end
