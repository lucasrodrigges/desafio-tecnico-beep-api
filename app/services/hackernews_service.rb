# frozen_string_literal: true
require 'net/http'
require 'json'

class HackernewsService
  HACKERNEWS_API_BASE_URL = "https://hacker-news.firebaseio.com/v0"

  def fetch_top_story_ids
    url = URI("#{HACKERNEWS_API_BASE_URL}/topstories.json")
    response = Net::HTTP.get(url)
    puts '[HackernewsService] fetch_top_story_ids called'
    result = JSON.parse(response)
    puts "[HackernewsService] fetch_top_story_ids result: \\#{result[0..4]}... (total: \\#{result.size})"
    result
  rescue
    []
    puts "[HackernewsService] fetch_top_story_ids error: \\#{e.message}"
  end

  def fetch_latest_story_ids
    url = URI("#{HACKERNEWS_API_BASE_URL}/newstories.json")
    response = Net::HTTP.get(url)
    puts '[HackernewsService] fetch_latest_story_ids called'
    result = JSON.parse(response)
    puts "[HackernewsService] fetch_latest_story_ids result: \\#{result[0..4]}... (total: \\#{result.size})"
    result
  rescue
    []
    puts "[HackernewsService] fetch_latest_story_ids error: \\#{e.message}"
  end

  def fetch_story(id)
    url = URI("#{HACKERNEWS_API_BASE_URL}/item/#{id}.json")
    response = Net::HTTP.get(url)
    puts "[HackernewsService] fetch_story called with id=\\#{id}"
    result = JSON.parse(response)
    puts "[HackernewsService] fetch_story result: \\#{result&.slice('id','title','by')}"
    result
  rescue
    nil
    puts "[HackernewsService] fetch_story error for id=\\#{id}: \\#{e.message}"
  end

  def fetch_comment(id)
    url = URI("#{HACKERNEWS_API_BASE_URL}/item/#{id}.json")
    response = Net::HTTP.get(url)
    puts "[HackernewsService] fetch_comment called with id=\\#{id}"
    result = JSON.parse(response)
    puts "[HackernewsService] fetch_comment result: \\#{result&.slice('id','by')}"
    result
  rescue
    nil
    puts "[HackernewsService] fetch_comment error for id=\\#{id}: \\#{e.message}"
  end

  def relevant_comments_for_story(story_id, min_words: 20)
    story = fetch_story(story_id)
    return [] unless story && story['kids']
    comments = story['kids'].map { |comment_id| fetch_comment(comment_id) }.compact
    puts "[HackernewsService] relevant_comments_for_story called with story_id=\\#{story_id}, min_words=\\#{min_words}"
    filtered = comments.select { |c| c['text'] && c['text'].split.size > min_words }
    puts "[HackernewsService] relevant_comments_for_story filtered count: \\#{filtered.size}"
    filtered.sort_by { |c| -(c['score'] || 0) }
  end

  def search_stories(keyword, max_ids: 30, limit: 10)
    keyword = keyword.to_s.strip.downcase
    return [] if keyword.empty?
    latest_ids = fetch_latest_story_ids.first(max_ids)
    stories = latest_ids.map { |id| fetch_story(id) }.compact
      puts "[HackernewsService] search_stories called with keyword=\\"#{keyword}\\", max_ids=\\#{max_ids}, limit=\\#{limit}"
      filtered = stories.select do |story|
        story['title']&.downcase&.include?(keyword) ||
        story['text']&.downcase&.include?(keyword) ||
        story['by']&.downcase&.include?(keyword)
      end
      puts "[HackernewsService] search_stories filtered count: \\#{filtered.size}"
      filtered.sort_by { |story| -story['time'].to_i }.first(limit)
  end
end
