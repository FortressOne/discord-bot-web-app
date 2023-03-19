class DiscordChannelPlayerTeam < ApplicationRecord
  belongs_to :team
  counter_culture :team

  belongs_to :discord_channel_player

  counter_culture(
    :discord_channel_player,
    column_name: Proc.new do |dcp_team|
      "winning_teams_count" if dcp_team.team.result == 'WIN'
    end
  )

  counter_culture(
    :discord_channel_player,
    column_name: Proc.new do |dcp_team|
      "losing_teams_count" if dcp_team.team.result == 'LOSE'
    end
  )

  counter_culture(
    :discord_channel_player,
    column_name: Proc.new do |dcp_team|
      "drawing_teams_count" if dcp_team.team.result == 'DRAW'
    end
  )

  has_one :trueskill_rating, as: :trueskill_rateable, dependent: :destroy
  has_many :discord_channel_player_team_rounds, dependent: :destroy
  has_many :rounds, through: :discord_channel_player_team_round

  after_create :create_trueskill_rating

  delegate :name, to: :discord_channel_player
  delegate :player, to: :discord_channel_player
  delegate :match, to: :team

  def emojis
    discord_channel_player_team_rounds.map(&:emoji).join("")
  end

  def images
    discord_channel_player_team_rounds.map(&:image)
  end
end
