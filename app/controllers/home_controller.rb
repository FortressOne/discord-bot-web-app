class HomeController < ApplicationController
  def index
    @matches = Match.completed.limit(1)
  end
end
