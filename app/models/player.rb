class Player < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  # devise :database_authenticatable, :registerable,
  #        :recoverable, :rememberable, :validatable
  devise :omniauthable, omniauth_providers: %i[discord]

  include ResultConstants

  has_many :discord_channel_players, dependent: :destroy
  has_many :discord_channels, through: :discord_channel_players
  has_many :teams, through: :discord_channel_players

  scope :visible, ->{ where(invisible: false) }

  def self.from_omniauth(auth)
    player = find_or_initialize_by(discord_id: auth.uid)
    player.email = auth.info.email
    # player.password = Devise.friendly_token[0, 20]
    player.image = auth.info.image # assuming the player model has an image
    # If you are using confirmable and the provider(s) you use validate emails, 
    # uncomment the line below to skip the confirmation emails.
    # player.skip_confirmation!
    player.save
    player
  end

  def last_match_date
    teams.last && teams.last.match.created_at
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
    teams.where.not(result: nil).count
  end

  def win_count
    result_count(WIN)
  end

  def loss_count
    result_count(LOSS)
  end

  def draw_count
    result_count(DRAW)
  end

  private

  def result_count(result)
    teams.where(result: result).size
  end
end
