class CreateTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :customer, foreign_key: true
      t.references :cash_session, foreign_key: true
      t.string :kasir, null: false
      t.decimal :subtotal, precision: 14, scale: 2, null: false
      t.decimal :diskon, precision: 14, scale: 2, null: false, default: 0
      t.decimal :total, precision: 14, scale: 2, null: false
      t.string :metode_pembayaran, null: false # tunai | transfer | qris
      t.decimal :uang_diterima, precision: 14, scale: 2
      t.decimal :kembalian, precision: 14, scale: 2
      t.datetime :terjadi_pada, null: false
      t.timestamps
    end
    add_index :transactions, [:user_id, :terjadi_pada]
  end
end
