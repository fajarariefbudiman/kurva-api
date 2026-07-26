class AddPaymentMethodToTransactions < ActiveRecord::Migration[7.1]
  def change
    # payment_method_id: link ke metode pembayaran yang dipilih (boleh kosong
    # kalau tokonya belum setup apa-apa → berarti Tunai default).
    #
    # payment_method_label: SNAPSHOT nama metode saat transaksi terjadi
    # (mis. "Transfer BCA - 1234567890 a.n Toko Saya"), supaya kalau
    # metode pembayarannya diedit/dihapus di kemudian hari, struk & riwayat
    # transaksi lama tidak ikut berubah/rusak.
    #
    # `metode_pembayaran` (kolom lama) TETAP dipakai, tapi sekarang isinya
    # kategori jenis (tunai/transfer/qris/lainnya) — dipakai untuk hitung
    # kas fisik saat tutup kas.
    add_reference :transactions, :payment_method, foreign_key: true, null: true
    add_column :transactions, :payment_method_label, :string
  end
end
