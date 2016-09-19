class CreateMarketplacesAndCreatorsAndModifyUsersAndAds < ActiveRecord::Migration
  def change

    create_table :creators do |t|
      t.belongs_to :user, index: true
    end  

    create_table :marketplaces, force: true do |t|
      t.belongs_to :creator, index: true
      t.string :name , limit: 140
      t.string :description
      t.string :pass
      t.string :address
      t.float :latitude
      t.float :longitude
      t.text :results, array: true, default: []
    end

    reversible do |dir|
      change_table :users do |t|
        dir.up   { t.belongs_to :marketplace, index: true, optional: true}
        dir.down { t.remove :marketplace_id }
      end
      change_table :ads do |t|
        dir.up   { t.belongs_to :marketplace, index: true, optional: true}
        dir.down { t.remove :marketplace_id }
      end
    end

  end
end
