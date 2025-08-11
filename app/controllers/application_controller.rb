require_relative './concerns/errors.rb'
class ApplicationController < ActionController::API
  include Errors

  before_action :rate_limit!
  before_action :handle_request_authorization!

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

  RATE_LIMIT = Rails.env.production? ? 10 : 100

  private
  def rate_limit!
    key = "rate_limit:#{request.ip}"
    count = RedisService.rate_limit(key, RATE_LIMIT)

    if count && count.to_i > RATE_LIMIT
      render json: { error: TOO_MANY_REQUESTS }, status: :too_many_requests
    end
  end

  def handle_request_authorization!
    ip = request.ip
    authorization = request.headers['Authorization']
    if RedisService.is_first_request(ip)
      new_authorization = RedisService.create_first_request_signature(ip)
      response.headers['Authorization'] = new_authorization
    else
      if authorization.nil? || !RedisService.has_valid_authorization(ip, authorization)
        render json: { error: UNAUTHORIZED }, status: :unauthorized
      end
    end
  end

  rescue_from StandardError do |_exception|
    Rails.logger.error("[ApplicationController] Unhandled error: #{_exception.message}")
    render json: { error: INTERNAL_ERROR }, status: :internal_server_error
  end
end
