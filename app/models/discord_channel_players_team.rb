class DiscordChannelPlayersTeam < ApplicationRecord
  belongs_to :team
  belongs_to :discord_channel_player
end
