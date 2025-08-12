require 'swagger_helper'

RSpec.describe 'Api::V1::Hackernews', type: :request do
  let(:hackernews_service) { instance_double(V1::HackernewsService) }

  before do
    allow(V1::HackernewsService).to receive(:new).and_return(hackernews_service)
  end

  describe 'GET /api/v1/hackernews/top_stories' do
    it 'lista as principais notícias do hackernews' do
      path '/api/v1/hackernews/top_stories' do
        get('lista as principais notícias do hackernews') do
          tags 'Hackernews'
          produces 'application/json'

          response(200, 'successful') do
            schema type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :integer },
                       title: { type: :string },
                       time: { type: :integer },
                       by: { type: :string },
                       score: { type: :integer },
                       descendants: { type: :integer },
                       type: { type: :string },
                       url: { type: :string },
                       kids: {
                         type: :array,
                         items: { type: :integer }
                       },
                       comments: {
                         type: :array,
                         items: {
                           type: :object,
                           properties: {
                             id: { type: :integer },
                             text: { type: :string },
                             score: { type: :integer },
                             by: { type: :string },
                             time: { type: :integer },
                             parent: { type: :integer },
                             type: { type: :string },
                             kids: {
                               type: :array,
                               items: { type: :integer }
                             }
                           }
                         }
                       }
                     },
                     required: %w[id title time by score type comments]
                   }

            let(:limit) { 15 }
            let(:stories) { Array.new(15) { |i| { 
              'id' => i, 
              'title' => "Story #{i}", 
              'time' => Time.now.to_i, 
              'by' => "user#{i}",
              'score' => 10 + i,
              'descendants' => i,
              'type' => 'story',
              'url' => "https://example#{i}.com",
              'kids' => [],
              'comments' => [] 
            } } }

            before do
              allow(hackernews_service).to receive(:fetch_top_stories_cached).with(50).and_return(stories)
            end

            run_test! do |response|
              data = JSON.parse(response.body)
              expect(data.size).to eq(15) # Sempre exatamente 15 stories
              expect(data.first['title']).to eq('Story 0')
              expect(data.first['comments']).to eq([])
              expect(data.first['by']).to eq('user0')
              expect(data.first['score']).to eq(10)
              expect(data.first['type']).to eq('story')
            end
          end

          response(200, 'successful - always returns exactly 15 stories') do
            let(:limit) { nil } # Parâmetro ignorado
            let(:stories) { Array.new(20) { |i| { 
              'id' => i, 
              'title' => "Story #{i}", 
              'time' => Time.now.to_i, 
              'by' => "user#{i}",
              'score' => 10 + i,
              'descendants' => i,
              'type' => 'story',
              'url' => "https://example#{i}.com",
              'kids' => [],
              'comments' => [] 
            } } }

            before do
              allow(hackernews_service).to receive(:fetch_top_stories_cached).with(50).and_return(stories)
            end

            run_test! do |response|
              data = JSON.parse(response.body)
              expect(data.size).to eq(15) # Sempre exatamente 15, mesmo com mais stories disponíveis
              data.each_with_index do |story, index|
                expect(story).to have_key('comments')
                expect(story['comments']).to eq([])
                expect(story['by']).to eq("user#{index}")
                expect(story['type']).to eq('story')
              end
            end
          end
        end
      end
    end
  end

  describe 'GET /api/v1/hackernews/{id}/relevant_comments' do
    it 'lista os comentários relevantes de uma notícia' do
      path '/api/v1/hackernews/{id}/relevant_comments' do
        get('lista os comentários relevantes de uma notícia') do
          tags 'Hackernews'
          produces 'application/json'
          parameter name: 'id', in: :path, type: :string, description: 'id'

          response(200, 'successful') do
            schema type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :integer },
                       text: { type: :string }
                     },
                     required: %w[id text]
                   }

            let(:id) { '123' }
            let(:comments) { [{ 'id' => 2, 'text' => 'A relevant comment' }] }

            before do
              allow(hackernews_service).to receive(:relevant_comments_for_story).with(id).and_return(comments)
            end

            run_test! do |response|
              data = JSON.parse(response.body)
              expect(data.size).to eq(1)
              expect(data.first['text']).to eq('A relevant comment')
            end
          end

          response(404, 'not found') do
            let(:id) { 'invalid_id' }

            before do
              allow(hackernews_service).to receive(:relevant_comments_for_story).with(id).and_return([])
            end

            run_test!
          end
        end
      end
    end
  end

  describe 'GET /api/v1/hackernews/search' do
    it 'busca notícias no hackernews' do
      path '/api/v1/hackernews/search' do
        get('busca notícias no hackernews') do
          tags 'Hackernews'
          produces 'application/json'
          parameter name: :query, in: :query, type: :string, description: 'Search keyword'

          response(200, 'successful') do
            schema type: :array,
                   items: {
                     type: :object,
                     properties: {
                       title: { type: :string }
                     },
                     required: ['title']
                   }

            let(:query) { 'ruby' }
            let(:results) { [{ 'title' => 'Story about Ruby' }] }

            before do
              allow(hackernews_service).to receive(:search_stories).with(query).and_return(results)
            end

            run_test! do |response|
              data = JSON.parse(response.body)
              expect(data.first['title']).to eq('Story about Ruby')
            end
          end

          response(422, 'unprocessable entity') do
            let(:query) { '' }
            run_test!
          end
        end
      end
    end
  end

  describe 'GET /api/v1/hackernews/replies_at_comments' do
    it 'lista as respostas de um comentário' do
      path '/api/v1/hackernews/replies_at_comments' do
        get('lista as respostas de um comentário') do
          tags 'Hackernews'
          produces 'application/json'
          parameter name: :ids, in: :query, type: :string, description: 'Comma-separated comment IDs'

          response(200, 'successful') do
            schema type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :integer },
                       text: { type: :string }
                     },
                     required: %w[id text]
                   }

            let(:ids) { '1,2' }
            let(:replies) { [{ 'id' => 3, 'text' => 'A reply' }] }

            before do
              allow(hackernews_service).to receive(:replies_at_comments).with(%w[1 2]).and_return(replies)
            end

            run_test! do |response|
              data = JSON.parse(response.body)
              expect(data.first['text']).to eq('A reply')
            end
          end

          response(422, 'unprocessable entity') do
            let(:ids) { '' }
            run_test!
          end
        end
      end
    end
  end
end
