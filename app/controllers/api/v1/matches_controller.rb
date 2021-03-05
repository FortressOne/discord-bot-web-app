require 'saulabs/trueskill'

class Api::V1::MatchesController < ActionController::API
  include Saulabs::TrueSkill

  def create
    discord_channel = DiscordChannel.find_or_create_by(match_params[:discord_channel])
    match = Match.create(discord_channel_id: discord_channel.id)

    match_params[:teams].each do |name, attrs|
      team = match.teams.new
      team.name = name
      team.result = attrs[:result].to_i

      attrs[:players].each do |discord_id, display_name|
        player = Player.find_or_create_by(discord_id: discord_id)
        player.name = display_name
        player.save

        discord_channel_players = player.discord_channel_players.find_or_create_by(
          discord_channel_id: discord_channel.id,
          player_id: player.id
        )

        team.discord_channel_players << discord_channel_players
      end

      team.save
    end

    match.game_map = map_params && GameMap.find_or_create_by(name: map_params)
    match.update_trueskill_ratings

    render json: match.id.to_json, status: :ok
  end

  private

  def map_params
    match_params[:map]
  end

  def match_params
    params
      .require(:match)
      .permit(
        :winner,
        :map,
        teams: {},
        discord_channel: {}
      )
  end
end
