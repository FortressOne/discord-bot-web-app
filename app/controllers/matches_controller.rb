class MatchesController < ApplicationController
  def index
    @matches = Match.order('id DESC')
  end
end
