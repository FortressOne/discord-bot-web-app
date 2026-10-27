class Results::Api::V1::FairTeamsController < ApplicationController
  include BotAuthentication

  # Only the pickup bot asks for fair teams (qwtf-discord-bot
  # get_fair_teams). It sends the same bearer token as /api/token.
  before_action :require_bot_token

  # Every split of the players is scored, so the work grows as
  # C(n-1, n/2-1): 6,435 splits at 16 players (8v8), billions at 40.
  MAX_PLAYERS = 16
  DISCORD_ID = /\A\d{1,20}\z/

  # Returns every team split, fairest (smallest skill gap) first:
  # [{ "1": [discord_id, ...], "2": [discord_id, ...] }, ...]
  # Read-only: unknown players and channels count as skill 0 instead of
  # being created.
  def new
    discord_ids = players_params
    channel_id = discord_channel_id_params.to_s

    unless valid_request?(discord_ids, channel_id)
      return render json: { error: "players must be 2-#{MAX_PLAYERS} distinct Discord ids" },
                    status: :unprocessable_entity
    end

    discord_ids = discord_ids.map { |discord_id| discord_id.to_i.to_s }
    discord_channel = DiscordChannel.find_by(channel_id: channel_id)
    skills = discord_ids.to_h { |discord_id| [discord_id, skill(discord_channel, discord_id)] }
    # Alternate which side gets listed first from match to match.
    swap_sides = discord_channel.present? && discord_channel.matches.count.odd?

    player1, *others = discord_ids
    teamsize = discord_ids.size / 2

    matchups = others.combination(teamsize - 1).map do |combo|
      team1 = combo + [player1]
      team2 = others - combo
      team1, team2 = team2, team1 if swap_sides
      { teams: { 1 => team1, 2 => team2 }, difference: (team1.sum { skills[_1] } - team2.sum { skills[_1] }).abs }
    end

    render json: matchups.sort_by.with_index { |matchup, i| [matchup[:difference], i] }.map { _1[:teams] },
           status: :ok
  end

  private

  def valid_request?(discord_ids, channel_id)
    discord_ids.is_a?(Array) &&
      discord_ids.size.between?(2, MAX_PLAYERS) &&
      discord_ids.all? { |discord_id| discord_id.is_a?(String) && discord_id.match?(DISCORD_ID) } &&
      discord_ids.map(&:to_i).uniq.size == discord_ids.size &&
      channel_id.match?(DISCORD_ID)
  end

  def skill(discord_channel, discord_id)
    return 0 unless discord_channel

    player = Player.find_by(discord_id: discord_id)
    return 0 unless player

    DiscordChannelPlayer.find_by(player: player, discord_channel: discord_channel)&.conservative_skill_estimate || 0
  end

  def players_params
    params.require(:players)
  end

  def discord_channel_id_params
    params.require(:channel_id)
  end
end
