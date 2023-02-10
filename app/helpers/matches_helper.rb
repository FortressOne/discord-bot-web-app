module MatchesHelper
  def match_summary(match)
    [match.description, match.size, match.map_name].compact.join(DELIMITER)
  end
end
