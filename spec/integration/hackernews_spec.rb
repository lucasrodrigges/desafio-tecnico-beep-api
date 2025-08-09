require 'swagger_helper'

RSpec.describe 'Hackernews API', type: :request do
  path '/hackernews/top_stories' do
    get 'Lista as principais notícias do Hackernews' do
      tags 'Hackernews'
      produces 'application/json'

      response '200', 'notícias encontradas' do
        run_test!
      end
    end
  end

  path '/hackernews/{id}/relevant_comments' do
    get 'Lista comentários relevantes de uma notícia' do
      tags 'Hackernews'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string, description: 'ID da notícia'

      response '200', 'comentários encontrados' do
        let(:id) { '1' }
        run_test!
      end
      response '404', 'notícia não encontrada' do
        let(:id) { '0' }
        run_test!
      end
    end
  end

  path '/hackernews/search' do
    get 'Busca notícias por palavra-chave' do
      tags 'Hackernews'
      produces 'application/json'
      parameter name: :query, in: :query, type: :string, description: 'Palavra-chave para busca'

      response '200', 'notícias encontradas' do
        let(:query) { 'rails' }
        run_test!
      end
      response '422', 'parâmetro ausente ou inválido' do
        let(:query) { nil }
        run_test!
      end
    end
  end
end
