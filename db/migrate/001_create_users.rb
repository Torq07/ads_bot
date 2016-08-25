class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users, force: true do |t|
      t.integer :uid
      t.string :phone
      t.string :fname
      t.string :lname
      t.string :address
      t.float :latitude
      t.float :longitude
      t.text :results, array: true, default: []
    end

    create_table :ads, force: true do |t|
      t.belongs_to :user, index: true
      t.string :message , limit: 140
      t.text :picture
      t.string :address
			t.float :latitude
			t.float :longitude
      t.date :expiration
    end
  end
end
