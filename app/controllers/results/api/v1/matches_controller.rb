require 'saulabs/trueskill'

class Results::Api::V1::MatchesController < ActionController::API
  include Saulabs::TrueSkill
  include ResultConstants

  def create
    discord_channel = DiscordChannel.find_or_create_by(
      channel_id: match_params[:discord_channel][:channel_id]
    )

    server = Server.find_or_create_by(
      address: match_params[:server][:address]
    )

    server.update(name: match_params[:server][:name])

    if !discord_channel.name && match_params.dig(:discord_channel, :name)
      disord_channel.update(name: match_params.dig(:discord_channel, :name))
    end

    match = Match.create(
      discord_channel_id: discord_channel.id,
      server_id: server.id,
      demo_uri: demo_uri_params
    )

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

    embed = Discordrb::Webhooks::Embed.new

    embed.add_field(
      name: "Match started on #{server.name}",
      value: "<qw://#{server.address}/observe>"
    )

    match.teams.each do |team|
      embed.add_field(
        inline: true,
        name: "#{team.colour} Team #{team.emoji}",
        value: team.players.map(&:name).join("\n")
      )
    end

    embed.add_field(
      name: "",
      value: "[demo](#{demo_uri_params})" # add stats etc
    )

    embed.footer = Discordrb::Webhooks::EmbedFooter.new(
      text: [
        "ID: #{match.id}",
        map_params,
      ].join(" · ")
    )

    Discordrb::API::Channel.create_message(
      "Bot #{Rails.application.credentials.discord[:token]}",
      discord_channel.channel_id,
      nil,
      false,
      embed
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

    scores = match.scores

    value = if match.drawn?
              "Draw"
            elsif match.winning_team.name == "1"
              "Blue wins by #{scores["1"] - scores["2"]} points"
            elsif match.winning_team.name == "2"
              "Red wins with #{seconds_to_str(match.time_left)} remaining"
            end

    embed.add_field(
      name: "Match finished on #{match.server.name}",
      value: value
    )

    team = match.teams.first
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

    team = match.teams.last
    embed.add_field(
      inline: true,
      name: "#{team.colour} Team #{team.emoji}",
      value: team.players.map(&:name).join("\n")
    )

    embed.add_field(
      name: "",
      value: "[demo](#{match.demo_uri})" # add stats etc
    )

    embed.footer = Discordrb::Webhooks::EmbedFooter.new(
      text: [
        "ID: #{match.id}",
        match.game_map.name
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

  def map_params
    match_params[:map]
  end

  def demo_uri_params
    match_params[:demo_uri]
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
