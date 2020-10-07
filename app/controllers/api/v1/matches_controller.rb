require 'saulabs/trueskill'

class Api::V1::MatchesController < ActionController::API
  include Saulabs::TrueSkill

  def create
    match = Match.create

    match_params[:teams].each do |name, attrs|
      team = match.teams.new
      team.name = name
      team.result = attrs[:result].to_i

      attrs[:players].each do |discord_id, display_name|
        player = Player.find_or_create_by(discord_id: discord_id)
        player.name = display_name
        player.save
        team.players << player
      end

      team.save
    end

    match.game_map = map_params && GameMap.find_or_create_by(name: map_params)

    match.save

    team1 = match.teams.find_by(name: 1)
    team2 = match.teams.find_by(name: 2)

    team1_rank = case team1.result
                 when 1 then 1
                 when 0 then 1
                 when -1 then 2
                 end

    team2_rank = case team2.result
                 when 1 then 1
                 when 0 then 1
                 when -1 then 2
                 end

    team1_players = team1.players
    team2_players = team2.players

    team1_player_ratings = team1_players.map do |player|
      Rating.new(player.trueskill_rating.skill, player.trueskill_rating.deviation)
    end

    team2_player_ratings = team2_players.map do |player|
      Rating.new(player.trueskill_rating.skill, player.trueskill_rating.deviation)
    end

    FactorGraph.new(
      team1_player_ratings => team1_rank,
      team2_player_ratings => team2_rank
    ).update_skills

    team1_players.each_with_index do |player, i|
      rating = team1_player_ratings[i]
      player.trueskill_rating.skill = rating.mean
      player.trueskill_rating.deviation = rating.deviation
      player.trueskill_rating.save
      player.save
    end

    team2_players.each_with_index do |player, i|
      rating = team2_player_ratings[i]
      player.trueskill_rating.skill = rating.mean
      player.trueskill_rating.deviation = rating.deviation
      player.trueskill_rating.save
      player.save
    end

    match.ratings_processed = true
    match.save

    render json: match.id.to_json, status: :ok
  end

  private

  def map_params
    match_params[:map]
  end

  def match_params
    params.require(:match).permit(:winner, :map, { teams: {} })
  end
end
