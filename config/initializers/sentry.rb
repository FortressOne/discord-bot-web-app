Sentry.init do |config|
  config.dsn = 'https://1ab037e07cb7457793ba34803812ba40@o4504933082923008.ingest.sentry.io/4504933083906048'
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Performance tracing: sample 5% of requests (it was 100%, a Sentry
  # transaction per request, mostly crawlers on /stats). Health checks on
  # /up are never traced. Errors are still reported in full.
  config.traces_sampler = lambda do |sampling_context|
    env = sampling_context[:env]
    next 0.0 if env && env["PATH_INFO"] == "/up"

    0.05
  end
end
