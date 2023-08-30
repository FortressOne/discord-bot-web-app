class MapSuggestion < ApplicationRecord
  RECENT_MAP_COUNT = 100
  CONSIDERED_TEAMSIZES = (1..6)

  belongs_to :discord_channel
  belongs_to :game_map, optional: true
  belongs_to :player, optional: true

  def self.index(channel_id:)
    discord_channel = DiscordChannel.find_by(
      channel_id: channel_id
    )

    CONSIDERED_TEAMSIZES.each_with_object({}) do |teamsize, h|
      maps = discord_channel
        .matches
        .order(created_at: :desc)
        .joins(:game_map)
        .for_teamsize(teamsize)
        .limit(RECENT_MAP_COUNT)
        .map { |ms| ms.game_map.name }

      h[teamsize] = maps
        .uniq
        .sort_by { |element| -maps.count(element) }
    end
  end

  def self.vote(attributes = {}, size)
    size.times.map { create(attributes).suggestion }
  end

  def initialize(attributes = {})
    if attributes[:discord_player_id]
      player = Player.find_or_create_by(
        discord_id: attributes.delete(:discord_player_id)
      )

      attributes[:player_id] = player.id
    end

    if attributes[:channel_id]
      attributes[:discord_channel_id] = DiscordChannel.find_or_create_by(
        channel_id: attributes.delete(:channel_id)
      ).id
    end

    super(attributes)
  end

  def suggestion
    last_thirty_maps = discord_channel
      .matches
      .joins(:game_map)
      .for_teamsize(for_teamsize)
      .order(created_at: :desc)
      .limit(RECENT_MAP_COUNT)
      .map(&:game_map)

    recently_suggested_maps = MapSuggestion
      .where(for_teamsize: for_teamsize)
      .where(discord_channel: discord_channel)
      .where("map_suggestions.updated_at > ?", 2.hours.ago)
      .order(updated_at: :desc)
      .joins(:game_map)
      .map(&:game_map)

    recently_played_maps = Match
      .where(discord_channel: discord_channel)
      .where("matches.created_at > ?", 6.hours.ago)
      .joins(:game_map)
      .map(&:game_map)

    suggested_maps = last_thirty_maps - recently_played_maps - recently_suggested_maps

    # if all maps have been recently played or suggested, then re-suggest some
    # but not any of the last three
    if suggested_maps.empty?
      suggested_maps = last_thirty_maps - recently_played_maps - recently_suggested_maps.first(3)
    end

    # if literally the entire pool of maps have been played, then re-suggest
    # already played maps
    if suggested_maps.empty?
      suggested_maps = last_thirty_maps - recently_suggested_maps.first(3)
    end

    # if there is still no map, just grab anything
    if suggested_maps.empty?
      suggestions_for_any_teamsize = MapSuggestion
        .joins(:game_map)
        .order(created_at: :desc)
        .limit(RECENT_MAP_COUNT)
        .map(&:game_map)

      suggested_maps = suggestions_for_any_teamsize - recently_suggested_maps.first(3)
    end

    update(game_map: suggested_maps.sample)
    game_map && game_map.name
  end
end
