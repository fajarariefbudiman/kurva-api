class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.references :user, null: false, foreign_key: true
      t.string :nama, null: false
      t.string :kategori, null: false, default: "Umum"
      t.decimal :harga_jual, precision: 14, scale: 2, null: false, default: 0
      t.decimal :harga_modal, precision: 14, scale: 2, null: false, default: 0
      t.integer :stok, null: false, default: 0
      t.string :foto_url
      t.timestamps
    end
    add_index :products, [:user_id, :nama]
  end
end
