class CreateStocks < ActiveRecord::Migration
  def change
    create_table :stocks do |t|
      t.string :ticker
      t.string :name
      t.string :exchange
      t.string :country
      t.string :category_name
      t.integer :category_number

      t.timestamps null: false
    end
  end
end
