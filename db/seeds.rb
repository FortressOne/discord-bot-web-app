# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

discord_channels = [
  DiscordChannel.create(channel_id: 744913000523366410, name: "Backtick #pugbot"),
  DiscordChannel.create(channel_id: 811577745686659083, name: "Backtick #pugbot2")
]

16.times do
  Player.create(
    discord_id: Faker::Number.number(digits: 18),
    name: Faker::Name.first_name
  )
end

128.times do
  players = Player.all.sample(8)
  match = Match.create

  match.game_map = GameMap.create(
    name: ["2fort5r", "mbasesr", "bam5", "well6"].sample
  )

  match.discord_channel = discord_channels.sample
  match.save

  result = [[1,-1], [0, 0], [-1, 1]].sample

  match.teams.create(
    name: 1,
    result: result[0],
    players: players[0..3]
  )

  match.teams.create(
    name: 2,
    result: result[1],
    players: players[4..7]
  )
end
