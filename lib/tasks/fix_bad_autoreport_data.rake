desc "fix bad autoreport data"
task fix_bad_autoreport_data: :environment do
  # Destroy matches without result
  Match
    .all
    .select { |m| !m.winning_team && !m.drawn? }
    .each(&:destroy)

  FIRST_AUTOREPORTED_MATCH = 4385

  # Destroy matches without server since autoreporting began
  Match
    .where("id >= ?", FIRST_AUTOREPORTED_MATCH)
    .where(server_id: nil)
    .destroy_all

  # Destroy matches without teams
  Match
    .where
    .missing(:teams)
    .destroy_all
end
