module ApplicationHelper
  include Pagy::Frontend

  def result(int)
    { 1 => "Win", 0 => "Draw", -1 => "Lose" }[int]
  end
end
