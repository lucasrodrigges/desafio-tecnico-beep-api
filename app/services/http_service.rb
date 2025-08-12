require 'net/http'
require 'openssl'

class HttpService
  MAX_RETRIES = 2 
  RETRY_DELAY = 0.3

  def self.make_request(url, retries = MAX_RETRIES)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.open_timeout = 5
    http.read_timeout = 15
    http.ssl_timeout = 5

    request = Net::HTTP::Get.new(url)
    response = http.request(request)
    
    if response.code == '200'
      response.body
    else
      raise "HTTP Error: #{response.code}"
    end
  rescue => e
    if retries > 0
      Rails.logger.warn "[HttpService] Request failed, retrying... (#{retries} attempts left): #{e.message}"
      sleep(RETRY_DELAY)
      make_request(url, retries - 1)
    else
      raise e
    end
  end
end
