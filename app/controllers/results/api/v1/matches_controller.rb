require 'saulabs/trueskill'

class Results::Api::V1::MatchesController < ActionController::API
  include Saulabs::TrueSkill
  include ResultConstants

  FINAL_ROUND = 1
  PENULTIMATE_ROUND = 2

  def create
    server = Server.find_or_create_by(address: server_params[:address])
    server.update(name: server_params[:name])
    server.matches.where(time_left: nil).destroy_all

    teams = match_params[:teams].to_hash

    reasons_to_bail = [
      teams.map { |_team_name, attrs| attrs["players"].count }.uniq.count > 1,
      teams.any? { |_team_name, attrs| attrs["players"].count == 0 }
    ]

    if reasons_to_bail.any?
      render json: { error: 'Invalid teams' }, status: :unprocessable_entity
      return
    end

    discord_channel = DiscordChannel.find_or_create_by(
      channel_id: discord_channel_params[:channel_id]
    )

    game_map = GameMap.find_or_create_by(name: map_params)

    match = Match.create(
      discord_channel_id: discord_channel.id,
      server_id: server.id,
      demo_uri: demo_uri_params,
      stats_uri: stats_uri_params,
      game_map_id: game_map.id
    )

    if rated_params
      match.update(rated: rated_params)
    end

    round = Round.create(match_id: match.id, number: PENULTIMATE_ROUND)

    match_params[:teams].each do |team_name, attrs|
      team = Team.create(match_id: match.id, name: team_name)

      attrs[:players].each do |player_attrs|
        player = Player.find(player_attrs[:id].split("#").last)

        discord_channel_player = DiscordChannelPlayer.find_or_create_by(
          player_id: player.id,
          discord_channel_id: discord_channel.id,
        )

        discord_channel_player_team = DiscordChannelPlayerTeam.create(
          discord_channel_player_id: discord_channel_player.id,
          team_id: team.id
        )

        discord_channel_player_team_round = DiscordChannelPlayerTeamRound.create(
          discord_channel_player_team_id: discord_channel_player_team.id,
          round_id: round.id,
          playerclass: player_attrs[:playerclass]
        )
      end
    end

    embed = Discordrb::Webhooks::Embed.new

    embed.author = Discordrb::Webhooks::EmbedAuthor.new(
      name: match.server.name,
      url: "http://phobos.baseq.fr:9999/join?url=#{match.server.address}",
      icon_url: "https://cdn.discordapp.com/icons/417258901810184192/aff794b4daac5f0a5cc7ee516f04abe7.jpg?size=256"
    )

    embed.description = [
      "Match has begun",
      match.size,
      match.game_map.name,
      "##{match.id}"
    ].join(DELIMITER)

    match.teams.each do |team|
      dcptrs = DiscordChannelPlayerTeamRound
        .where(round: round)
        .select { |dcptr| dcptr.team == team }

      embed.add_field(
        inline: true,
        name: " #{team.emoji} #{team.description}",
        value: dcptrs.map { |dcptr| "#{dcptr.emoji} #{dcptr.name}" }.join("\n")
      )
    end

    embed.add_field(
      name: "",
      value: [
        "[spectate](http://phobos.baseq.fr:9999/observe?url=#{match.server.address})",
      ].join(DELIMITER)
    )

    Rails.logger.info("Embed Object: #{embed.to_json}") # Assuming `embed` responds to `to_json` or similar method

    token = Rails.application.credentials.discord[:token]
    Rails.logger.info("Discord Token (masked): #{token[0..3]}...#{token[-4..-1]}") # Only show the first and last few characters for security

    Discordrb::API::Channel.create_message(
      "Bot #{Rails.application.credentials.discord[:token]}",
      discord_channel.channel_id,
      nil,
      false,
      embed,
    )

    response_json = match.id.to_json
    Rails.logger.info("Response: #{response_json}")
    render json: response_json, status: :ok
  end

  def update
    match = Match.find(match_params["id"])
    discord_channel = match.discord_channel
    winner = match_params["winner"]
    teams = match.teams

    match_params["teams"].each do |team_name, attrs|
      teams.find_by(name: team_name).update(score: attrs[:score])
    end

    embed = Discordrb::Webhooks::Embed.new

    embed.author = Discordrb::Webhooks::EmbedAuthor.new(
      name: match.server.name,
      url: "http://phobos.baseq.fr:9999/join?url=#{match.server.address}",
      icon_url: "https://cdn.discordapp.com/icons/417258901810184192/aff794b4daac5f0a5cc7ee516f04abe7.jpg?size=256"
    )

    if !winner
      round = Round.create(match_id: match.id, number: FINAL_ROUND)

      match_params[:teams].each do |team_name, attrs|
        team = Team.find_by(match_id: match.id, name: team_name)

        attrs[:players].each do |player_attrs|
          player = Player.find(player_attrs[:id].split("#").last)

          discord_channel_player = DiscordChannelPlayer.find_by(
            player_id: player.id,
            discord_channel_id: match.discord_channel.id,
          )

          discord_channel_player_team = DiscordChannelPlayerTeam.find_by(
            discord_channel_player_id: discord_channel_player.id,
            team_id: team.id
          )

          discord_channel_player_team_round = DiscordChannelPlayerTeamRound.create(
            discord_channel_player_team_id: discord_channel_player_team.id,
            round_id: round.id,
            playerclass: player_attrs[:playerclass]
          )
        end
      end

      embed.description = [
        "Round 2 has begun",
        match.size,
        match.game_map.name,
        "##{match.id}"
      ].join(DELIMITER)

      teams.find_by(name: "1").tap do |team|
        dcptrs = DiscordChannelPlayerTeamRound
          .where(round: round)
          .select { |dcptr| dcptr.team == team }

        embed.add_field(
          inline: true,
          name: " #{team.emoji} #{team.description}",
          value: dcptrs.map { |dcptr| "#{dcptr.emoji} #{dcptr.name}" }.join("\n")
        )
      end

      embed.add_field(
        inline: true,
        name: match.score,
        value: ""
      )

      teams.find_by(name: "2").tap do |team|
        dcptrs = DiscordChannelPlayerTeamRound
          .where(round: round)
          .select { |dcptr| dcptr.team == team }

        embed.add_field(
          inline: true,
          name: " #{team.emoji} #{team.description}",
          value: dcptrs.map { |dcptr| "#{dcptr.emoji} #{dcptr.name}" }.join("\n")
        )
      end

      embed.add_field(
        name: "",
        value: [
          "[spectate](http://phobos.baseq.fr:9999/observe?url=#{match.server.address})",
        ].join(DELIMITER)
      )

      Discordrb::API::Channel.create_message(
        "Bot #{Rails.application.credentials.discord[:token]}",
        discord_channel.channel_id,
        nil,
        false,
        embed,
      )
    else
      match.update(time_left: match_params["timeleft"])

      teams.each do |team|
        score = match_params[:teams][team.name][:score]

        result = case winner
                 when "0" then DRAW
                 when team.name then WIN
                 else LOSS
                 end

        team.update(
          score: score,
          result: result
        )
      end

      match.update_trueskill_ratings
      scores = match.scores

      embed.description = [
        match.description,
        match.size,
        match.game_map.name,
        "##{match.id}"
      ].join(DELIMITER)

      embed.color = match.result_colour

      teams.find_by(name: "1").tap do |team|
        embed.add_field(
          inline: true,
          name: "#{team.emoji} #{team.description}",
          value: team.discord_channel_player_teams.map do |dcpt|
            "#{dcpt.emojis} #{dcpt.name}"
          end.join("\n")
        )
      end

      embed.add_field(
        inline: true,
        name: match.score,
        value: ""
      )

      teams.find_by(name: "2").tap do |team|
        embed.add_field(
          inline: true,
          name: "#{team.emoji} #{team.description}",
          value: team.discord_channel_player_teams.map do |dcpt|
            "#{dcpt.emojis} #{dcpt.name}"
          end.join("\n")
        )
      end

      embed.add_field(
        name: "",
        value: [
          "[Summary](#{match_url})",
          "[Stats](#{match.stats_uri})",
          "[Demo](#{match.demo_uri})",
        ].join(DELIMITER)
      )

      Discordrb::API::Channel.create_message(
        "Bot #{Rails.application.credentials.discord[:token]}",
        discord_channel.channel_id,
        nil,
        false,
        embed
      )
    end

    response_json = match.id.to_json
    Rails.logger.info("Response: #{response_json}")
    render json: response_json, status: :ok
  end

  private

  def discord_channel_params
    match_params[:discord_channel]
  end

  def server_params
    match_params[:server]
  end

  def map_params
    match_params[:map]
  end

  def demo_uri_params
    match_params[:demo_uri]
  end

  def stats_uri_params
    match_params[:stats_uri]
  end

  def rated_params
    match_params[:rated]
  end

  def match_params
    params
      .require(:match)
      .permit(
        :id,
        :rated,
        :winner,
        :timeleft,
        :map,
        :demo_uri,
        :stats_uri,
        :round,
        server: {},
        teams: {},
        discord_channel: {}
      )
  end
end
