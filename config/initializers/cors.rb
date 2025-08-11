Rails.application.config.middleware.insert_before 0, Rack::Cors do
	allow do
		if Rails.env.production?
			origins 'https://desafio-tecnico-beep-front-production.up.railway.app'
		elsif Rails.env.development?
			origins 'http://localhost:5173'
		end

		resource '*',
			headers: :any,
			expose: ['Authorization', 'access-token'],
			methods: [:get, :post, :put, :patch, :delete, :options, :head],
			credentials: false
	end
end
