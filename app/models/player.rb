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
    find_or_create_by(discord_id: auth.uid) do |player|
      player.email = auth.info.email
      # player.password = Devise.friendly_token[0, 20]
      player.image = auth.info.image # assuming the player model has an image
      # If you are using confirmable and the provider(s) you use validate emails, 
      # uncomment the line below to skip the confirmation emails.
      # player.skip_confirmation!
    end
  end

  def match_count
    matches.size
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
