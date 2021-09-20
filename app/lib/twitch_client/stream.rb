class TwitchClient::Stream
  def initialize(data)
    @data = data
  end

  def user_name
    @data["user_name"]
  end

  def user_login
    @data["user_login"]
  end
end
