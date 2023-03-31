Sentry.init do |config|
  config.dsn = 'https://1ab037e07cb7457793ba34803812ba40@o4504933082923008.ingest.sentry.io/4504933083906048'
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Set traces_sample_rate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production.
  config.traces_sample_rate = 1.0
  # or
  config.traces_sampler = lambda do |context|
    true
  end
end
