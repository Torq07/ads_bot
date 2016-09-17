class CreateMarketplaces < ActiveRecord::Migration
  def change

    create_table :marketplaces, force: true do |t|
      t.belongs_to :user, index: true
      t.string :name , limit: 140
      t.string :description
      t.string :pass
      t.string :address
      t.float :latitude
      t.float :longitude
      t.text :results, array: true, default: []
    end

  end
end
