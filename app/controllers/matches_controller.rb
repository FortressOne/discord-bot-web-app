class MatchesController < ApplicationController
  before_action :set_match, only: %i[ show ]

  def index
    @pagy, @matches = pagy(Match.completed)
  end

  def show
  end

  private

  def set_match
    @match = Match.find(params[:id])
  end

  def match_params
    params.fetch(:match, {})
  end
end
