module ShipstationClient
  def self.client
    @client ||= HTTParty
  end

  def self.auth
    {
      username: ENV["SHIPSTATION_API_KEY"],
      password: ENV["SHIPSTATION_API_SECRET"]
    }
  end
end
