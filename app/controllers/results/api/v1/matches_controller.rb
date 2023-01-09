require 'saulabs/trueskill'

class Results::Api::V1::MatchesController < ActionController::API
  include Saulabs::TrueSkill
  include ResultConstants

  def create
    discord_channel = DiscordChannel.find_or_create_by(
      channel_id: match_params[:discord_channel][:channel_id]
    )

    if !discord_channel.name && match_params.dig(:discord_channel, :name)
      disord_channel.update(name: match_params.dig(:discord_channel, :name))
    end

    match = Match.create(discord_channel_id: discord_channel.id)

    match_params[:teams].each do |name, attrs|
      team = match.teams.create(name: name)

      if attrs[:result]
        team.result = attrs[:result].to_i
      else
        attrs[:players].each do |player_attrs|
          player = Player.find_or_create_by(player_attrs)

          if !player.name && player_attrs[:name]
            player.update(name: player_attrs[:name])
          end

          discord_channel_player = DiscordChannelPlayer.find_or_create_by(
            player_id: player.id,
            discord_channel_id: discord_channel.id,
          )

          team.discord_channel_players << discord_channel_player
        end
      end

      team.save
    end

    if map_params
      match.update(game_map: GameMap.find_or_create_by(name: map_params))
    end

    if match.teams.all? { |team| team.result != nil }
      match.update_trueskill_ratings
    end

    render json: match.id.to_json, status: :ok
  end

  def update
    match = Match.find(match_params["id"])
    winner = match_params["winner"]

    match.teams.each do |team|
      result = case winner
               when "0" then DRAW
               when team.name then WIN
               else
                 LOSS
               end

      team.update(result: result)
    end

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
        :id,
        :winner,
        :map,
        teams: {},
        discord_channel: {}
      )
  end
end
