class MapSuggestion < ApplicationRecord
  belongs_to :discord_channel
  belongs_to :game_map, optional: true
  belongs_to :player, optional: true

  after_create :update_suggestion

  def suggestion
    game_map && game_map.name
  end

  private

  def update_suggestion
    last_thirty_maps = discord_channel
      .matches
      .completed
      .order(created_at: :desc)
      .limit(30)
      .map(&:game_map)

    recently_suggested_maps = MapSuggestion
      .where(discord_channel: discord_channel)
      .where("created_at > ?", 2.hours.ago)
      .includes(:game_map)
      .map(&:game_map)

    recently_played_maps = Match
      .completed
      .where(discord_channel: discord_channel)
      .where("matches.created_at > ?", 6.hours.ago)
      .map(&:game_map)

    suggested_maps = last_thirty_maps - recently_suggested_maps - recently_played_maps

    if suggested_maps.empty?
      suggested_maps = last_thirty_maps - recently_played_maps
    end

    if suggested_maps.empty?
      suggested_maps = last_thirty_maps
    end

    update(game_map: suggested_maps.sample)
  end
end
