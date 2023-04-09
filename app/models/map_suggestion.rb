class MapSuggestion < ApplicationRecord
  belongs_to :discord_channel
  belongs_to :game_map, optional: true
  belongs_to :player, optional: true

  def self.vote(attributes = {})
    [
      create(attributes).suggestion,
      create(attributes).suggestion,
      create(attributes).suggestion
    ]
  end

  def initialize(attributes = {})
    if attributes[:discord_player_id]
      attributes[:player_id] = Player.find_or_create_by(
        discord_id: attributes[:discord_player_id],
        name: attributes[:discord_player_name]
      ).id
    end

    if attributes[:channel_id]
      attributes[:discord_channel_id] = DiscordChannel.find_by(
        channel_id: attributes.delete(:channel_id)
      ).id
    end

    super(attributes)
  end

  def suggestion
    last_thirty_maps = discord_channel
      .matches
      .joins(:game_map)
      .where.not(game_maps: { id: nil })
      .for_teamsize(for_teamsize)
      .order(created_at: :desc)
      .limit(30)
      .map(&:game_map)

    recently_suggested_maps = MapSuggestion
      .where(discord_channel: discord_channel)
      .where("updated_at > ?", 2.hours.ago)
      .includes(:game_map)
      .map(&:game_map)

    recently_played_maps = Match
      .where(discord_channel: discord_channel)
      .where("matches.created_at > ?", 6.hours.ago)
      .joins(:game_map)
      .where.not(game_maps: { id: nil })
      .map(&:game_map)

    suggested_maps = last_thirty_maps

    if suggested_maps.empty?
      suggested_maps = last_thirty_maps - recently_played_maps
    end

    if suggested_maps.empty?
      suggested_maps = last_thirty_maps
    end

    update(game_map: suggested_maps.sample)
    game_map && game_map.name
  end
end
