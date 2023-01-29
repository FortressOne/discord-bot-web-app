require 'saulabs/trueskill'

class Results::Api::V1::MatchesController < ActionController::API
  include Saulabs::TrueSkill
  include ResultConstants

  DELIMITER = " · "

  def create
    discord_channel = DiscordChannel.find_or_create_by(
      channel_id: discord_channel_params[:channel_id]
    )

    server = Server.find_or_create_by(address: server_params[:address])
    server.update(name: server_params[:name])

    game_map = GameMap.find_or_create_by(name: map_params)

    match = Match.create(
      discord_channel_id: discord_channel.id,
      server_id: server.id,
      demo_uri: demo_uri_params,
      stats_uri: stats_uri_params,
      game_map_id: game_map.id
    )

    round = Round.create(match_id: match.id, number: 1)

    match_params[:teams].each do |team_name, attrs|
      team = Team.create(match_id: match.id, name: team_name)

      attrs[:players].each do |player_attrs|
        player = Player.find_by(auth_token: player_attrs[:auth_token])

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

    if match.teams.all? { |team| team.result != nil }
      match.update_trueskill_ratings
    end

    embed = Discordrb::Webhooks::Embed.new

    embed.author = Discordrb::Webhooks::EmbedAuthor.new(
      name: match.server.name,
      url: "http://phobos.baseq.fr:9999/join?url=#{match.server.address}",
      icon_url: "https://cdn.discordapp.com/icons/417258901810184192/aff794b4daac5f0a5cc7ee516f04abe7.jpg?size=256"
    )

    embed.description = [
      "Match starting",
      match.teams.map { |team| team.players.size }.join("v"),
      match.game_map.name,
      "##{match.id}"
    ].join(DELIMITER)

    match.teams.each do |team|
      dcptrs = DiscordChannelPlayerTeamRound
        .where(round: round)
        .select { |dcptr| dcptr.team == team }

      embed.add_field(
        inline: true,
        name: " #{team.emoji} #{team.colour.titleize} Team",
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

    render json: match.id.to_json, status: :ok
  end

  def update
    match = Match.find(match_params["id"])
    discord_channel = match.discord_channel

    teams = match.teams

    winner = match_params["winner"]

    if !winner
      round = Round.create(match_id: match.id, number: 2)

      match_params[:teams].each do |team_name, attrs|
        team = Team.find_by(match_id: match.id, name: team_name)

        attrs[:players].each do |player_attrs|
          player = Player.find_by(auth_token: player_attrs[:auth_token])

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

      embed = Discordrb::Webhooks::Embed.new

      embed.author = Discordrb::Webhooks::EmbedAuthor.new(
        name: match.server.name,
        url: "http://phobos.baseq.fr:9999/join?url=#{match.server.address}",
        icon_url: "https://cdn.discordapp.com/icons/417258901810184192/aff794b4daac5f0a5cc7ee516f04abe7.jpg?size=256"
      )

      embed.description = [
        "Second round starting",
        teams.map { |team| team.players.size }.join("v"),
        match.game_map.name,
        "##{match.id}"
      ].join(DELIMITER)

      teams.each do |team|
        dcptrs = DiscordChannelPlayerTeamRound
          .where(round: round)
          .select { |dcptr| dcptr.team == team }

        embed.add_field(
          inline: true,
          name: " #{team.emoji} #{team.colour.titleize} Team",
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

      embed = Discordrb::Webhooks::Embed.new

      embed.author = Discordrb::Webhooks::EmbedAuthor.new(
        name: match.server.name,
        url: "http://phobos.baseq.fr:9999/join?url=#{match.server.address}",
        icon_url: "https://cdn.discordapp.com/icons/417258901810184192/aff794b4daac5f0a5cc7ee516f04abe7.jpg?size=256"
      )

      scores = match.scores

      description = if match.drawn?
                      "Draw"
                    elsif match.winning_team.name == "1"
                      "Blue wins by #{scores["1"] - scores["2"]} points"
                    elsif match.winning_team.name == "2"
                      "Red wins with #{seconds_to_str(match.time_left)} remaining"
                    end

      embed.description = [
        description,
        teams.map { |team| team.players.size }.join("v"),
        match.game_map.name,
        "##{match.id}"
      ].join(DELIMITER)

      teams.find_by(name: "1").tap do |team|
        embed.add_field(
          inline: true,
          name: "#{team.emoji} #{team.colour.titleize} Team",
          value: team.discord_channel_player_teams.map do |dcpt|
            "#{dcpt.emojis} #{dcpt.name}"
          end.join("\n")
        )
      end

      embed.add_field(
        inline: true,
        name: [scores["1"], scores["2"]].join(" — "),
        value: ""
      )

      teams.find_by(name: "2").tap do |team|
        embed.add_field(
          inline: true,
          name: "#{team.emoji} #{team.colour.titleize} Team",
          value: team.discord_channel_player_teams.map do |dcpt|
            "#{dcpt.emojis} #{dcpt.name}"
          end.join("\n")
        )
      end

      embed.add_field(
        name: "",
        value: [
          "[demo](#{match.demo_uri})",
          "[stats](#{match.stats_uri})"
        ].join(" · ")
      )

      Discordrb::API::Channel.create_message(
        "Bot #{Rails.application.credentials.discord[:token]}",
        discord_channel.channel_id,
        nil,
        false,
        embed
      )
    end

    render json: match.id.to_json, status: :ok
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

  def match_params
    params
      .require(:match)
      .permit(
        :id,
        :winner,
        :timeleft,
        :map,
        :demo_uri,
        :stats_uri,
        server: {},
        teams: {},
        discord_channel: {}
      )
  end

  def seconds_to_str(seconds)
    ["#{seconds / 3600}h", "#{seconds / 60 % 60}m", "#{seconds % 60}s"]
      .select { |str| str =~ /[1-9]/ }.join(" ")
  end
end
