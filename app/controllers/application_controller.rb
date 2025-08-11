require_relative './concerns/errors.rb'
class ApplicationController < ActionController::API
  include Errors

  def index
    render json: { 
      message: "Beep HackerNews API is running", 
      version: "1.0.0",
      status: "healthy",
      endpoints: {
        docs: "/docs",
      }
    }
  end

	rescue_from StandardError do |_exception|
		render json: { error: INTERNAL_ERROR }, status: :internal_server_error
	end
end
