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

        discord_channel_player_team = DiscordChannelPlayersTeam.create(
          discord_channel_player_id: discord_channel_player.id,
          team_id: team.id
        )

        discord_channel_player_round = DiscordChannelPlayerRound.create(
          discord_channel_player_id: discord_channel_player.id,
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

    ["1", "2"].each do |team_name|
      team = match.teams.find_by(name: team_name)

      discord_channel_player_teams = DiscordChannelPlayersTeam.where(team: team)

      discord_channel_players_in_team = team.discord_channel_players

      discord_channel_player_rounds = DiscordChannelPlayerRound
        .where(round: round)
        .and(
          DiscordChannelPlayerRound.where(
            discord_channel_player: discord_channel_players_in_team
          )
        )

      binding.pry

      # could be optimised
      dcprs = DiscordChannelPlayerRound.where(
        discord_channel_player_id: team.discord_channel_players.map(&:id),
        round_id: round.id
      )

      binding.pry

      embed.add_field(
        inline: true,
        name: " #{team.emoji} #{team.colour.titleize} Team",
        value: dcprs.map { |dcpr| "#{dcpr.emoji} #{dcpr.discord_channel_player.player.name}" }.join("\n")
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
    match.update(time_left: match_params["timeleft"])
    winner = match_params["winner"]

    match.teams.each do |team|
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
      match.teams.map { |team| team.players.size }.join("v"),
      match.game_map.name,
      "##{match.id}"
    ].join(DELIMITER)

    team = match.teams.find_by(name: "1")
    embed.add_field(
      inline: true,
      name: "#{team.colour} Team #{team.emoji}",
      value: team.players.map(&:name).join("\n")
    )

    embed.add_field(
      inline: true,
      name: [scores["1"], scores["2"]].join(" — "),
      value: ""
    )

    match.teams.find_by(name: "2").tap do |team|
      embed.add_field(
        inline: true,
        name: "#{team.emoji} #{team.colour} Team",
        value: team.players.map do |p|
          "#{Rails.application.config.team_emojis["blank"]} #{p.name}"
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

    discord_channel = match.discord_channel

    Discordrb::API::Channel.create_message(
      "Bot #{Rails.application.credentials.discord[:token]}",
      discord_channel.channel_id,
      nil,
      false,
      embed
    )

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
