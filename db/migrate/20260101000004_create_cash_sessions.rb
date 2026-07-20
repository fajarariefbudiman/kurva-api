class CreateCashSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :cash_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :kasir, null: false
      t.datetime :dibuka_pada, null: false
      t.decimal :modal_awal, precision: 14, scale: 2, null: false
      t.datetime :ditutup_pada
      t.decimal :total_penjualan, precision: 14, scale: 2
      t.decimal :total_tunai, precision: 14, scale: 2
      t.decimal :total_non_tunai, precision: 14, scale: 2
      t.decimal :total_hpp, precision: 14, scale: 2
      t.decimal :kas_akhir_sistem, precision: 14, scale: 2
      t.decimal :kas_akhir_fisik, precision: 14, scale: 2
      t.decimal :selisih_kas, precision: 14, scale: 2
      t.integer :jumlah_transaksi
      t.text :catatan
      t.timestamps
    end
  end
end
