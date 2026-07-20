class CreateFinancialRecords < ActiveRecord::Migration[7.1]
  def change
    # Satu tabel untuk 6 jenis catatan keuangan (dibedakan lewat `kind`):
    #   modal      → setoran pemilik untuk mendanai usaha
    #   capex      → belanja aset (belum termasuk penyusutan)
    #   opex       → biaya rutin bulanan
    #   expense    → pengeluaran lain di luar rutin & aset
    #   kas_masuk  → kas masuk dicatat dari halaman Kasir
    #   kas_keluar → kas keluar dicatat dari halaman Kasir
    # COGS/HPP sengaja TIDAK disimpan di sini karena dihitung otomatis
    # dari transaction_items (harga_modal x qty) — lihat ReportsController.
    create_table :financial_records do |t|
      t.references :user, null: false, foreign_key: true
      t.references :cash_session, foreign_key: true
      t.string :kind, null: false
      t.string :nama, null: false
      t.string :kategori
      t.decimal :jumlah, precision: 14, scale: 2, null: false
      t.date :tanggal, null: false
      t.boolean :berulang, default: false # dipakai khusus kind: opex
      t.text :catatan
      t.timestamps
    end
    add_index :financial_records, [:user_id, :kind, :tanggal]
  end
end
