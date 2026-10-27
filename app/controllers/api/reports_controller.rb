# Match report endpoint for QWTF-Live progs (ssqc/json.qc ReportMatchResult).
# The progs POST a report at match start, halftime, and end, and ignore the
# response body; they only need a 2xx. The full payload is persisted verbatim
# so results can be processed into matches/ratings later.
#
# Unauthenticated: game servers call it with no credentials (uri_post with a
# bare JSON body), so requiring a token would break every live server. It is
# capped instead: ApiBodyLimit 413s oversized bodies before parsing, and the
# payload must look like a report.
class Api::ReportsController < ActionController::API
  MAX_BODY_BYTES = ApiBodyLimit::MAX_BYTES

  def create
    # Backstop for bodies sent without a Content-Length.
    return head :content_too_large if request.raw_post.bytesize > MAX_BODY_BYTES

    payload = JSON.parse(request.raw_post)
    return head :bad_request unless payload.is_a?(Hash)

    fields = payload.slice(*MatchReport::STRING_FIELDS)
    return head :unprocessable_entity unless fields.values.all? { |value| value.nil? || value.is_a?(String) }

    MatchReport.create!(**fields.symbolize_keys, payload: payload)

    head :ok
  rescue JSON::ParserError
    head :bad_request
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_entity
  end
end
