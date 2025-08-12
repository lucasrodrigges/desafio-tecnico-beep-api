require 'net/http'
require 'openssl'

class HttpService
  def self.make_request(url)
    Rails.logger.debug "[HttpService] Making request to: #{url}"
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(url)
    response = http.request(request)
    response.body
  rescue => e
    Rails.logger.error "[HttpService] Request failed: #{e.class} - #{e.message}"
    raise e
  end
end
