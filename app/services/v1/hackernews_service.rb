require 'json'

module V1
  class HackernewsService
    HACKERNEWS_API_BASE_URL = "https://hacker-news.firebaseio.com/v0"
    MAX_CONCURRENT_THREADS = 20
    BATCH_SIZE = 50

    def fetch_top_stories(limit = 15)
      ids = fetch_top_story_ids.first(limit)
      stories = process_stories_in_batches(ids)
      stories
    end

    def fetch_top_stories_cached
      stories = RedisService.fetch_top_stories_cache

      unless stories && stories.length >= 15
        ids = fetch_top_story_ids.first(30)
        stories = process_stories_in_batches(ids)
        stories = stories.select { |story| story && story['title'] }

        if stories.length < 15
          additional_ids = fetch_top_story_ids.slice(30, 100) || []
          additional_stories = process_stories_in_batches(additional_ids)
          additional_stories = additional_stories.select { |story| story && story['title'] }
          stories.concat(additional_stories)
        end
        
        RedisService.create_top_stories_cache(stories)
      end

      stories
    end

    def fetch_top_story_ids
      url = URI("#{HACKERNEWS_API_BASE_URL}/topstories.json")
      response = HttpService.make_request(url)
      result = JSON.parse(response)
      result
    rescue => e
      Rails.logger.error "[HackernewsService] fetch_top_story_ids error: #{e.message}"
      []
    end

    def fetch_multiple_stories(ids)
      process_bulk_items_in_batches(ids) { |id| fetch_story(id) }
    end

    def fetch_multiple_comments(ids)
      process_bulk_items_in_batches(ids) { |id| fetch_comment(id) }
    end

    def replies_at_comments(ids)
      process_comments_in_batches(ids)
    end

    def fetch_latest_story_ids
      url = URI("#{HACKERNEWS_API_BASE_URL}/newstories.json")
      response = HttpService.make_request(url)
      result = JSON.parse(response)
      result
    rescue => e
      Rails.logger.error "[HackernewsService] fetch_latest_story_ids error: #{e.message}"
      []
    end

    def fetch_story(id)
      url = URI("#{HACKERNEWS_API_BASE_URL}/item/#{id}.json")
      response = HttpService.make_request(url)
      result = JSON.parse(response)
      result
    rescue => e
      Rails.logger.error "[HackernewsService] fetch_story error for id=#{id}: #{e.message}"
      nil
    end

    def fetch_comment(id)
      url = URI("#{HACKERNEWS_API_BASE_URL}/item/#{id}.json")
      response = HttpService.make_request(url)
      result = JSON.parse(response)
      result
    rescue => e
      Rails.logger.error "[HackernewsService] fetch_comment error for id=#{id}: #{e.message}"
      nil
    end

    def relevant_comments_for_story(story_id, min_words: 20)
      story = fetch_story(story_id)
      return [] unless story && story['kids']
      
      comment_ids = story['kids']
      comments = process_comments_in_batches(comment_ids, filter_by_text: false)
      filtered = filter_comments_in_batches(comments, min_words: min_words)
      filtered.sort_by { |c| -(c['score'] || 0) }
    end

    def search_stories(keyword, max_ids: 100, limit: 10)
      keyword = keyword.to_s.strip.downcase
      return [] if keyword.empty?

      stories = RedisService.get_stories_cache

      unless stories
        latest_ids = fetch_latest_story_ids.first(max_ids)
        stories = process_stories_in_batches(latest_ids, include_comments: false)
        RedisService.create_stories_cache(stories)
      end

      filtered = filter_stories_by_keyword_in_batches(stories, keyword)
      filtered = filtered.sort_by { |story| -story['time'].to_i }.first(limit)
      
      filtered.each do |story|
        unless story['comments']
          relevant_comments = relevant_comments_for_story(story['id'])
          story['comments'] = relevant_comments || []
        end
      end
      
      filtered
    end

    private

    def process_stories_in_batches(ids, include_comments: true)
      stories = []
      stories_mutex = Mutex.new
      
      ids.each_slice(MAX_CONCURRENT_THREADS) do |batch|
        threads = batch.map do |id|
          Thread.new do
            story = fetch_story(id)
            if story
              if include_comments
                relevant_comments = relevant_comments_for_story(id)
                story['comments'] = relevant_comments || []
              end
              stories_mutex.synchronize { stories << story }
            end
          rescue => e
            Rails.logger.error "[HackernewsService] Error processing story #{id}: #{e.message}"
          end
        end
        threads.each(&:join)
      end
      
      stories
    end

    def process_comments_in_batches(ids, filter_by_text: true)
      comments = []
      comments_mutex = Mutex.new
      
      ids.each_slice(MAX_CONCURRENT_THREADS) do |batch|
        threads = batch.map do |id|
          Thread.new do
            comment = fetch_comment(id)
            if comment
              should_include = if filter_by_text
                                comment['text'] && comment['by']
                              else
                                true
                              end
              comments_mutex.synchronize { comments << comment } if should_include
            end
          rescue => e
            Rails.logger.error "[HackernewsService] Error processing comment #{id}: #{e.message}"
          end
        end
        threads.each(&:join)
      end
      
      comments
    end

    def filter_comments_in_batches(comments, min_words: 20)
      filtered_comments = []
      
      comments.each_slice(BATCH_SIZE) do |batch|
        batch_filtered = batch.select do |comment|
          comment['text'] && comment['text'].split.size > min_words
        end
        filtered_comments.concat(batch_filtered)
      end
      
      filtered_comments
    end

    def filter_stories_by_keyword_in_batches(stories, keyword)
      filtered_stories = []
      
      stories.each_slice(BATCH_SIZE) do |batch|
        batch_filtered = batch.select do |story|
          story['title']&.downcase&.include?(keyword) ||
          story['text']&.downcase&.include?(keyword) ||
          story['by']&.downcase&.include?(keyword)
        end
        filtered_stories.concat(batch_filtered)
      end
      
      filtered_stories
    end

    def process_bulk_items_in_batches(ids, &block)
      results = []
      results_mutex = Mutex.new
      
      ids.each_slice(MAX_CONCURRENT_THREADS) do |batch|
        threads = batch.map do |id|
          Thread.new do
            result = block.call(id)
            results_mutex.synchronize { results << result } if result
          rescue => e
            Rails.logger.error "[HackernewsService] Error processing bulk item #{id}: #{e.message}"
          end
        end
        threads.each(&:join)
      end
      
      results
    end
  end
end
