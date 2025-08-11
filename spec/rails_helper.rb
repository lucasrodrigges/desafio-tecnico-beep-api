require 'spec_helper'
require_relative '../config/environment'
require 'rspec/rails'

ENV['RAILS_ENV'] ||= 'test'

abort("The Rails environment is running in production mode!") if Rails.env.production?

RSpec.configure do |config|
  config.use_active_record = false

  config.filter_rails_from_backtrace!
end
