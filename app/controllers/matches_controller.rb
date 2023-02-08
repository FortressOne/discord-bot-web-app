class MatchesController < ApplicationController
  before_action :set_match, only: %i[ show ]

  # GET /matches or /matches.json
  # def index
  #   @matches = Match.all
  # end

  # GET /matches/1 or /matches/1.json
  def show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_match
      @match = Match.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def match_params
      params.fetch(:match, {})
    end
end
