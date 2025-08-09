require_relative './concerns/errors.rb'
class ApplicationController < ActionController::API
  include Errors

	rescue_from StandardError do |_exception|
		render json: { error: INTERNAL_ERROR }, status: :internal_server_error
	end
end
