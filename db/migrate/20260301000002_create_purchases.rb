class CreatePurchases < ActiveRecord::Migration[7.1]
  def change
    create_table :purchases do |t|
      t.references :user, null: false, foreign_key: true
      t.references :supplier, foreign_key: true
      t.string :no_faktur
      t.string :penerima, null: false
      t.decimal :subtotal, precision: 14, scale: 2, null: false
      t.decimal :diskon, precision: 14, scale: 2, null: false, default: 0
      t.decimal :total, precision: 14, scale: 2, null: false
      t.string :status_pembayaran, null: false, default: "lunas" # lunas | hutang
      t.string :metode_pembayaran # tunai | transfer | qris | lainnya (kalau lunas)
      t.datetime :terjadi_pada, null: false
      t.text :catatan
      t.timestamps
    end
    add_index :purchases, [:user_id, :terjadi_pada]
    add_index :purchases, [:user_id, :status_pembayaran]
  end
end
