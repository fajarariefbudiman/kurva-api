class CreatePurchaseItems < ActiveRecord::Migration[7.1]
  def change
    create_table :purchase_items do |t|
      t.references :purchase, null: false, foreign_key: true
      t.references :product, foreign_key: true
      t.string :nama, null: false
      t.decimal :harga_beli, precision: 14, scale: 2, null: false
      t.integer :qty, null: false
      t.timestamps
    end
  end
end
