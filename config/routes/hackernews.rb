get 'hackernews/top_stories', to: 'hackernews#top_stories'

get 'hackernews/:id/relevant_comments', to: 'hackernews#relevant_comments'

# Rota para busca por palavra-chave
get 'hackernews/search', to: 'hackernews#search'
