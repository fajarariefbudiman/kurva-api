class CreateTransactionItems < ActiveRecord::Migration[7.1]
  def change
    create_table :transaction_items do |t|
      t.references :transaction, null: false, foreign_key: true
      t.references :product, foreign_key: true
      t.string :nama, null: false
      t.decimal :harga, precision: 14, scale: 2, null: false
      t.decimal :harga_modal, precision: 14, scale: 2, null: false, default: 0
      t.integer :qty, null: false
      t.timestamps
    end
  end
end
