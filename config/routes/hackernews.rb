namespace :api do
	namespace :v1 do
		get 'hackernews/top_stories', to: 'hackernews#top_stories'
		get 'hackernews/:id/relevant_comments', to: 'hackernews#relevant_comments'
		get 'hackernews/search', to: 'hackernews#search'
		get 'hackernews/replies_at_comments', to: 'hackernews#replies_at_comments'
	end
end
