source "https://rubygems.org"

gem "rails", "~> 8.0.2"
gem "puma", ">= 5.0"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "kamal", require: false
gem "thruster", require: false
gem "rack-cors"
gem "redis", ">= 4.0"
gem "dotenv-rails"
gem "rufus-scheduler", "~> 3.9"
gem 'rswag'
gem 'jwt'

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false  
  gem 'rspec-rails'
  gem 'webmock'
end

