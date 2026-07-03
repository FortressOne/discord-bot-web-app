# Match report endpoint for QWTF-Live progs (ssqc/json.qc ReportMatchResult).
# The progs POST a report at match start, halftime, and end, and ignore the
# response body; they only need a 2xx. The full payload is persisted verbatim
# so results can be processed into matches/ratings later.
class Api::ReportsController < ActionController::API
  def create
    payload = JSON.parse(request.raw_post)

    MatchReport.create!(
      game_token: payload["game_token"],
      report_type: payload["report_type"],
      map: payload["map"],
      server_name: payload["server_name"],
      server_address: payload["server_address"],
      payload: payload
    )

    head :ok
  rescue JSON::ParserError
    head :bad_request
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_entity
  end
end
