# A stale tab can POST the sign-in form with a CSRF token from a rotated
# session (e.g. the user already signed in from another tab). The token
# verifier then raises inside the OmniAuth middleware, which surfaces as a
# raw error page. Convert it to an OmniAuth failure so the request routes
# to the callbacks controller's #failure (a redirect home) instead.
OmniAuth.config.request_validation_phase = lambda do |env|
  OmniAuth::RailsCsrfProtection::TokenVerifier.new.call(env)
rescue ActionController::InvalidAuthenticityToken
  raise OmniAuth::AuthenticityError, "Stale or missing CSRF token"
end
