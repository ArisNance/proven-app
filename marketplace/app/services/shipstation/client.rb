module Shipstation
  class Client
    BASE_URL = ENV.fetch("SHIPSTATION_API_BASE_URL", "https://ssapi.shipstation.com")

    def get(path_or_url, query: {})
      url = absolute_url(path_or_url)
      response = HTTParty.get(
        url,
        basic_auth: {
          username: ENV["SHIPSTATION_API_KEY"],
          password: ENV["SHIPSTATION_API_SECRET"]
        },
        query: query,
        headers: { "Accept" => "application/json" }
      )

      raise "ShipStation request failed: #{response.code} #{response.body}" unless response.success?

      response.parsed_response
    end

    def post(path_or_url, body: {})
      url = absolute_url(path_or_url)
      response = HTTParty.post(
        url,
        basic_auth: {
          username: ENV["SHIPSTATION_API_KEY"],
          password: ENV["SHIPSTATION_API_SECRET"]
        },
        headers: {
          "Accept" => "application/json",
          "Content-Type" => "application/json"
        },
        body: body.to_json
      )

      raise "ShipStation request failed: #{response.code} #{response.body}" unless response.success?

      response.parsed_response
    end

    private

    def absolute_url(path_or_url)
      value = path_or_url.to_s
      return value if value.start_with?("http://", "https://")
      return "#{BASE_URL}#{value}" if value.start_with?("/")

      "#{BASE_URL}/#{value}"
    end
  end
end
