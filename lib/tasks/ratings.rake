require 'saulabs/trueskill'

namespace :ratings do
  desc "build ratings from scratch"
  task build: :environment do
    include Saulabs::TrueSkill

    TrueskillRating.destroy_all

    Player.all.each do |player|
      player.create_trueskill_rating
    end

    Match.all.each do |match|
      team1 = Team.find_by(match_id: match.id, name: 1)
      team2 = Team.find_by(match_id: match.id, name: 2)

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
        puts '===='
        puts player.name
        puts player.trueskill_rating.skill
      end

      team2_players.each_with_index do |player, i|
        rating = team2_player_ratings[i]
        player.trueskill_rating.skill = rating.mean
        player.trueskill_rating.deviation = rating.deviation
        player.trueskill_rating.save
        player.save
        puts '===='
        puts player.name
        puts player.trueskill_rating.skill
      end

      match.ratings_processed = true
      match.save
    end
  end
end
