class RenameTrueSkillSkillToMean < ActiveRecord::Migration[6.0]
  def change
     rename_column :trueskill_ratings, :skill, :mean
  end
end
