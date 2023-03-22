class Player < ApplicationRecord
  include ResultConstants

  IMAGES = [
    "blue_demoman.webp",
    "blue_engineer.webp",
    "blue_hwguy.webp",
    "blue_medic.webp",
    "blue_pyro.webp",
    "blue_scout.webp",
    "blue_sniper.webp",
    "blue_soldier.webp",
    "blue_spy.webp",
    "red_demoman.webp",
    "red_engineer.webp",
    "red_hwguy.webp",
    "red_medic.webp",
    "red_pyro.webp",
    "red_scout.webp",
    "red_sniper.webp",
    "red_soldier.webp",
    "red_spy.webp",
  ]

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # devise :database_authenticatable, :registerable,
  #        :recoverable, :rememberable, :validatable

  devise :rememberable, :omniauthable, omniauth_providers: %i[discord]

  has_many :discord_channel_players, dependent: :destroy
  has_many :discord_channels, through: :discord_channel_players
  has_many :teams, through: :discord_channel_players
  has_many :matches, through: :teams

  has_secure_token :auth_token

  scope :visible, ->{ where(invisible: false) }

  def self.from_omniauth(auth)
    player = find_or_initialize_by(discord_id: auth.uid)
    player.email = auth.info.email
    # player.password = Devise.friendly_token[0, 20]
    player.name = auth.info.name
    player.image = auth.info.image || "home/classes/#{IMAGES.sample}"
    # If you are using confirmable and the provider(s) you use validate emails, 
    # uncomment the line below to skip the confirmation emails.
    # player.skip_confirmation!
    player.save
    player
  end

  def get_auth_token
    self.regenerate_auth_token if self.auth_token.nil?
    self.auth_token
  end

  def last_match_date
    teams.any? && teams.last { |team| team.created_at }.created_at
  end

  def discord_channel_players_with_matches_played
    discord_channel_players
      .sort_by(&:match_count)
      .reverse
      .filter do |dcp|
      dcp.teams.any?
    end
  end

  def match_count
    win_count + loss_count + draw_count
  end

  def win_count
    discord_channel_players.sum { |dcp| dcp.winning_teams_count }
  end

  def loss_count
    discord_channel_players.sum { |dcp| dcp.losing_teams_count }
  end

  def draw_count
    discord_channel_players.sum { |dcp| dcp.drawing_teams_count }
  end
end
