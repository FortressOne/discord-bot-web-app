desc "fix bad autoreport data"
task fix_bad_autoreport_data: :environment do
    FIRST_AUTOREPORTED_MATCH = 4385

  # Destroy matches without server since autoreporting began
  Match
    .where("id >= ?", FIRST_AUTOREPORTED_MATCH)
    .where(server_id: nil)
    .destroy_all

  # Destroy matches without result
  Match
    .where("id >= ?", FIRST_AUTOREPORTED_MATCH)
    .where(time_left: nil)
    .destroy_all

  # Destroy matches without teams
  Match
    .where
    .missing(:teams)
    .destroy_all
end
