class DiscordChannelPlayerTeam < ApplicationRecord
  include ResultConstants

  belongs_to :team
  counter_culture :team
  belongs_to :discord_channel_player
  has_one :trueskill_rating, as: :trueskill_rateable, dependent: :destroy
  has_many :discord_channel_player_team_rounds, dependent: :destroy
  has_many :rounds, through: :discord_channel_player_team_round

  counter_culture :discord_channel_player, column_name: 'teams_count'

  counter_culture(
    :discord_channel_player,
    column_name: proc do |model|
      case model.team.result
      when WIN  then 'winning_teams_count'
      when DRAW then 'drawing_teams_count'
      when LOSS then 'losing_teams_count'
      end
    end,
    column_names: {
      ["discord_channel_player_teams.team_id IN (?)", Team.where(result: WIN).select(:id)] => 'winning_teams_count',
      ["discord_channel_player_teams.team_id IN (?)", Team.where(result: DRAW).select(:id)] => 'drawing_teams_count',
      ["discord_channel_player_teams.team_id IN (?)", Team.where(result: LOSS).select(:id)] => 'losing_teams_count'
    }
  )

  delegate :name, to: :discord_channel_player
  delegate :player, to: :discord_channel_player
  delegate :match, to: :team
  delegate :result, to: :team

  def conservative_skill_estimate
    trueskill_rating && trueskill_rating.conservative_skill_estimate
  end

  def emojis
    discord_channel_player_team_rounds.map(&:emoji).join("")
  end

  def images
    discord_channel_player_team_rounds.map(&:image)
  end
end
