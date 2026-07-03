# One in-game "Sign in with Discord" pairing attempt (device-code flow).
# The game menu mints a code (POST /api/device), the player approves it at
# /link while signed in via Discord, and the menu polls GET /api/device/:code
# until the TFL token is released — exactly once.
class DeviceCode < ApplicationRecord
  # No I/L/O/0/1: players may type the code by hand from the game menu.
  ALPHABET = %w[A B C D E F G H J K M N P Q R S T U V W X Y Z 2 3 4 5 6 7 8 9].freeze
  TTL = 10.minutes

  belongs_to :player, optional: true

  validates :code, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[pending approved claimed] }

  def self.mint
    where(expires_at: ...Time.current).delete_all
    create!(code: generate_code, expires_at: TTL.from_now)
  end

  def self.find_active(raw)
    code = normalize(raw)
    return if code.nil?

    where("expires_at > ?", Time.current).find_by(code: code)
  end

  # Accepts "abcd1234", "ABCD-1234", "abcd 1234"... -> "ABCD-1234"
  def self.normalize(raw)
    cleaned = raw.to_s.upcase.gsub(/[^A-Z0-9]/, "")
    return unless cleaned.length == 8

    "#{cleaned[0, 4]}-#{cleaned[4, 4]}"
  end

  def self.generate_code
    loop do
      code = Array.new(2) { Array.new(4) { ALPHABET.sample }.join }.join("-")
      break code unless exists?(code: code)
    end
  end

  # Binds the code to the approving player. False if the code was already
  # used, so a second approval can't rebind someone else's pairing.
  def approve(approving_player)
    return false unless status == "pending"

    update!(player: approving_player, status: "approved")
  end

  # Releases the login token exactly once.
  def claim!
    with_lock do
      return nil unless status == "approved" && player

      update!(status: "claimed")
      TflToken.mint(player)
    end
  end
end
