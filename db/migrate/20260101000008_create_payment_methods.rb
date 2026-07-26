class CreatePaymentMethods < ActiveRecord::Migration[7.1]
  def change
    # Metode pembayaran dikonfigurasi per-toko (per user) lewat CRUD di
    # halaman Pengaturan. `jenis` dipakai untuk kategori tunai vs non-tunai
    # (dipakai CashSessionsController#close buat hitung kas fisik — cuma
    # transaksi TUNAI yang nambah kas di laci). `bank`/`nomor_rekening`/
    # `atas_nama` hanya relevan kalau jenis == "transfer".
    create_table :payment_methods do |t|
      t.references :user, null: false, foreign_key: true
      t.string :nama, null: false           # nama tampilan, mis. "Transfer BCA"
      t.string :jenis, null: false           # tunai | transfer | qris | lainnya
      t.string :bank
      t.string :nomor_rekening
      t.string :atas_nama
      t.boolean :aktif, default: true, null: false
      t.timestamps
    end
    add_index :payment_methods, [:user_id, :aktif]
  end
end
