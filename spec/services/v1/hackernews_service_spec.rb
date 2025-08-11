require 'rails_helper'
require 'webmock/rspec'

RSpec.describe V1::HackernewsService, type: :service do
  let(:service) { described_class.new }
  let(:base_url) { described_class::HACKERNEWS_API_BASE_URL }

  describe '#fetch_top_story_ids' do
    it 'retorna um array com os IDs das principais notícias' do
      stub_request(:get, "#{base_url}/topstories.json")
        .to_return(status: 200, body: '[1, 2, 3]')
      
      ids = service.fetch_top_story_ids
      expect(ids).to eq([1, 2, 3])
    end

    it 'retorna um array vazio quando há erro na API' do
      stub_request(:get, "#{base_url}/topstories.json")
        .to_return(status: 500)
      
      ids = service.fetch_top_story_ids
      expect(ids).to eq([])
    end
  end

  describe '#fetch_story' do
    it 'retorna os detalhes da notícia para um ID específico' do
      story_id = 1
      story_data = { 'id' => story_id, 'title' => 'Test Story' }.to_json
      
      stub_request(:get, "#{base_url}/item/#{story_id}.json")
        .to_return(status: 200, body: story_data)
      
      story = service.fetch_story(story_id)
      expect(story['title']).to eq('Test Story')
    end

    it 'retorna nil se a notícia não for encontrada' do
      story_id = 999
      stub_request(:get, "#{base_url}/item/#{story_id}.json")
        .to_return(status: 404)
      
      story = service.fetch_story(story_id)
      expect(story).to be_nil
    end
  end

  describe '#fetch_top_stories' do
    it 'busca uma lista das principais notícias com comentários relevantes' do
      stub_request(:get, "#{base_url}/topstories.json")
        .to_return(status: 200, body: '[1, 2]')
      
      stub_request(:get, "#{base_url}/item/1.json")
        .to_return(status: 200, body: { 'id' => 1, 'title' => 'First Story', 'time' => Time.now.to_i }.to_json)
      
      stub_request(:get, "#{base_url}/item/2.json")
        .to_return(status: 200, body: { 'id' => 2, 'title' => 'Second Story', 'time' => Time.now.to_i }.to_json)

      stories = service.fetch_top_stories(2)
      expect(stories.size).to eq(2)
      expect(stories.map { |s| s['id'] }).to match_array([1, 2])
      
      stories.each do |story|
        expect(story).to have_key('comments')
        expect(story['comments']).to be_an(Array)
      end
    end

    it 'inclui comentários relevantes quando a story possui kids' do
      stub_request(:get, "#{base_url}/topstories.json")
        .to_return(status: 200, body: '[1]')
      
      story_with_kids = { 'id' => 1, 'title' => 'Story with comments', 'time' => Time.now.to_i, 'kids' => [101, 102] }
      stub_request(:get, "#{base_url}/item/1.json")
        .to_return(status: 200, body: story_with_kids.to_json)
      
      relevant_comment = {
        'id' => 101,
        'text' => 'Este é um comentário muito longo e relevante com mais de vinte palavras para passar pelo filtro com sucesso e ser incluído nos resultados.',
        'score' => 15
      }
      
      short_comment = {
        'id' => 102,
        'text' => 'Comentário curto.',
        'score' => 5
      }
      
      stub_request(:get, "#{base_url}/item/101.json")
        .to_return(status: 200, body: relevant_comment.to_json)
      
      stub_request(:get, "#{base_url}/item/102.json")
        .to_return(status: 200, body: short_comment.to_json)

      stories = service.fetch_top_stories(1)
      expect(stories.size).to eq(1)
      
      story = stories.first
      expect(story['id']).to eq(1)
      expect(story['comments']).to be_an(Array)
      expect(story['comments'].size).to eq(1)
      expect(story['comments'].first['id']).to eq(101)
    end
  end

  describe '#relevant_comments_for_story' do
    let(:story_id) { 1 }
    
    it 'retorna comentários com mais de 20 palavras, ordenados por pontuação decrescente' do
      story_with_kids = { 'id' => story_id, 'kids' => [101, 102, 103] }
      
      comment1 = { 
        'id' => 101, 
        'text' => 'Este é um comentário muito longo e relevante com mais de vinte palavras para passar pelo filtro com sucesso e ser incluído.',
        'score' => 10 
      }
      
      comment2 = { 
        'id' => 102, 
        'text' => 'Comentário curto.', 
        'score' => 5 
      }
      
      comment3 = { 
        'id' => 103, 
        'text' => 'Outro comentário super interessante e detalhado que tem palavras suficientes para ser considerado relevante pelo nosso serviço de aplicação e teste adequadamente.',
        'score' => 20 
      }

      allow(service).to receive(:fetch_story).with(story_id).and_return(story_with_kids)
      
      call_count = 0
      allow(service).to receive(:fetch_comment) do |comment_id|
        call_count += 1
        case comment_id
        when 101 then comment1
        when 102 then comment2  
        when 103 then comment3
        else nil
        end
      end

      comments = service.relevant_comments_for_story(story_id)
      
      expect(comments.size).to eq(2)
      
      comment_ids = comments.map { |c| c['id'] }
      expect(comment_ids).to contain_exactly(101, 103)
      
      expect(comments.first['score']).to be >= comments.last['score']
    end

    it 'filtra comentários com exatamente 20 palavras' do
      story_with_comment = { 'id' => story_id, 'kids' => [104] }
      
      twenty_word_comment = { 
        'id' => 104, 
        'text' => 'This comment has exactly twenty words in total to test the filtering logic properly here now done.',
        'score' => 15 
      }
      
      allow(service).to receive(:fetch_story).with(story_id).and_return(story_with_comment)
      allow(service).to receive(:fetch_comment).with(104).and_return(twenty_word_comment)

      comments = service.relevant_comments_for_story(story_id)
      expect(comments).to be_empty
    end

    it 'retorna um array vazio se a notícia não possui comentários' do
      story_without_kids = { 'id' => story_id, 'kids' => nil }
      allow(service).to receive(:fetch_story).with(story_id).and_return(story_without_kids)
      comments = service.relevant_comments_for_story(story_id)
      expect(comments).to be_empty
    end

    it 'retorna um array vazio se a notícia não existe' do
      allow(service).to receive(:fetch_story).with(story_id).and_return(nil)
      comments = service.relevant_comments_for_story(story_id)
      expect(comments).to be_empty
    end
  end

  describe '#replies_at_comments' do
    it 'busca detalhes para os IDs de comentários fornecidos' do
      comment_ids = %w[1 2]
      comment1 = { 'id' => 1, 'text' => 'First reply', 'by' => 'user1' }
      comment2 = { 'id' => 2, 'text' => 'Second reply', 'by' => 'user2' }

      allow(service).to receive(:fetch_comment).with('1').and_return(comment1)
      allow(service).to receive(:fetch_comment).with('2').and_return(comment2)

      replies = service.replies_at_comments(comment_ids)
      expect(replies.size).to eq(2)
      expect(replies.map { |r| r['by'] }).to match_array(%w[user1 user2])
    end
  end

  describe '#search_stories' do
    before do
      allow(RedisService).to receive(:get_stories_cache).and_return(nil)
      allow(RedisService).to receive(:create_stories_cache)
    end

    it 'busca notícias por palavra-chave' do
      allow(service).to receive(:fetch_latest_story_ids).and_return([1, 2, 3])
      
      story1 = { 'id' => 1, 'title' => 'A story about Ruby on Rails', 'time' => Time.now.to_i }
      story2 = { 'id' => 2, 'title' => 'A story about JavaScript', 'time' => Time.now.to_i }
      story3 = { 'id' => 3, 'title' => 'Another story about ruby', 'time' => Time.now.to_i }

      allow(service).to receive(:fetch_story).with(1).and_return(story1)
      allow(service).to receive(:fetch_story).with(2).and_return(story2)
      allow(service).to receive(:fetch_story).with(3).and_return(story3)

      results = service.search_stories('ruby')
      expect(results.size).to eq(2)
      expect(results.map { |r| r['id'] }).to match_array([1, 3])
    end

    it 'retorna um array vazio se a palavra-chave estiver em branco' do
      results = service.search_stories('   ')
      expect(results).to be_empty
    end
  end
end
