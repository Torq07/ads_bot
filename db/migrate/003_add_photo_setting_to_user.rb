class AddPhotoSettingToUser < ActiveRecord::Migration
  def change

    reversible do |dir|
      change_table :users do |t|
        dir.up   do
          t.boolean :photo_setting
        end 
        dir.down do 
          t.remove :photo_setting
        end
      end
    end

  end
end