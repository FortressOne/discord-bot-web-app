require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  config.action_mailer.default_url_options = { host: "fortressone.org" }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  config.hosts << "host.docker.internal"
  config.web_console.permissions = '172.20.0.2'

  config.discord = { server_id: "744911007859736616" }

  config.team_emojis = {
    1 => "<:flag_1:1062548481576800307>",
    2 => "<:flag_2:1062548478422679625>",
    3 => "<:flag_3:1062548475402788954>",
    4 => "<:flag_4:1062548473163034625>",
    "blank" => "<:blank:1063494588158988318>",
  }

  config.playerclass_emojis = {
    blue: {
      1 => "<:blue_scout:1065445775674462219>",
      2 => "<:blue_sniper:1065445777649963019>",
      3 => "<:blue_soldier:1065445781013794897>",
      4 => "<:blue_demoman:1065445762575642624>",
      5 => "<:blue_medic:1065445770045698069>",
      6 => "<:blue_hwguy:1065445767424262164>",
      7 => "<:blue_pyro:1065445772293832834>",
      8 => "<:blue_spy:1065445782657962106>",
      9 => "<:blue_engineer:1065445763779395645>",
    },
    red: {
      1 => "<:red_scout:1065445797660999750>",
      2 => "<:red_sniper:1065445799183536228>",
      3 => "<:red_soldier:1065445802190852137>",
      4 => "<:red_demoman:1065445785518493706>",
      5 => "<:red_medic:1065445791587631164>",
      6 => "<:red_hwguy:1065445790060924938>",
      7 => "<:red_pyro:1065445794167140414>",
      8 => "<:red_spy:1065445853617209414>",
      9 => "<:red_engineer:1065445788488060928>",
    }
  }
end
