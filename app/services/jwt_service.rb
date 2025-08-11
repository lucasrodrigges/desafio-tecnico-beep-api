require 'redis'
require 'json'
require 'securerandom'
require 'jwt'

class JWTService
  
  SECRET = ENV['JWT_SECRET']
  ALGORITHM = 'HS256'

  private

  def self.encode(payload)
    JWT.encode(payload, SECRET, ALGORITHM)
  end

  def self.decode(token)
    JWT.decode(token, SECRET, true, { algorithm: ALGORITHM })[0]
  rescue JWT::DecodeError => e
    Rails.logger.warn("[JWTService] JWT decode error: #{e.message}")
    nil
  end
end