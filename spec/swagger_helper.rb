require 'rails_helper'

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('swagger').to_s
  
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'API V1',
        version: 'v1'
      },
      paths: {},
      servers: [
        {
          url: ENV['APP_URL'] || 'http://localhost:3000',
          variables: {
            defaultHost: {
              default: ENV['APP_URL'] || 'http://localhost:3000'
            }
          }
        }
      ]
    }
  }

  config.openapi_format = :yaml
end
