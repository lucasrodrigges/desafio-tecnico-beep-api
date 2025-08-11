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
    user_agent = request.headers['User-Agent']
    authorization_header = request.headers['Authorization']
    device_id = request.headers['X-Device-ID']
    
    authorization = nil
    if authorization_header&.start_with?('Bearer ')
      authorization = authorization_header.split(' ', 2)[1]
    else
      authorization = authorization_header
    end

    if RedisService.is_first_request(ip, user_agent, device_id)
      auth_data = RedisService.create_first_request_signature(ip, user_agent, device_id)
      if auth_data
        response.headers['Authorization'] = auth_data[:token]
        response.headers['X-Device-ID'] = auth_data[:device_id]
      else
        render json: { error: INTERNAL_ERROR }, status: :internal_server_error
        return
      end
    else
      if authorization.nil? || !RedisService.has_valid_authorization(ip, user_agent, authorization, device_id)
        Rails.logger.warn("[ApplicationController] Authorization failed for IP: #{ip}, token: #{authorization.inspect}")
        render json: { error: UNAUTHORIZED }, status: :unauthorized
        return
      end
    end
  rescue => e
    Rails.logger.error("[ApplicationController] Authorization error: #{e.message}")
    render json: { error: UNAUTHORIZED }, status: :unauthorized
  end

  rescue_from StandardError do |_exception|
    Rails.logger.error("[ApplicationController] Unhandled error: #{_exception.message}")
    render json: { error: INTERNAL_ERROR }, status: :internal_server_error
  end
end
