module MatchesHelper
  def match_summary(match)
    [match.id, match.description, match.size, match.map_name].compact.join(DELIMITER)
  end

  def match_location(match)
    if match.server 
      link_to(match.server.name, "qw://#{match.server.address}") 
    elsif match.discord_channel && match.discord_channel.invite_url
      link_to(match.discord_channel.name, match.discord_channel.invite_url) 
    elsif match.discord_channel
      match.discord_channel.name
    else 
      "Unknown location"
    end 
  end
end
