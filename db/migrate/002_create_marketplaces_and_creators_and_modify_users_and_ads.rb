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
      t.boolean :agreament
      t.integer :banned_id, array: true, default: []
    end

    reversible do |dir|
      change_table :users do |t|
        dir.up   do
          t.belongs_to :marketplace, index: true, optional: true
          t.integer :requested_marketplace_id
          t.integer :current_admin_marketplace_id
        end 
        dir.down do 
          t.remove :marketplace_id 
          t.remove :requested_marketplace_id 
          t.remove :current_admin_marketplace_id
        end
      end
      change_table :ads do |t|
        dir.up   { t.belongs_to :marketplace, index: true, optional: true}
        dir.down { t.remove :marketplace_id }
      end
    end

  end
end
