class AddAmortizationFieldsToFinancialRecords < ActiveRecord::Migration[7.1]
  def change
    # Dipakai khusus buat kind: 'capex', untuk menghitung penyusutan
    # (depresiasi) otomatis tiap bulan:
    #   jenis_akad    → 'sewa' atau 'beli' (cara aset itu didapat)
    #   tanggal_mulai → tanggal aset mulai dipakai (dasar hitung penyusutan)
    #   durasi_bulan  → umur ekonomis aset dalam bulan (mis. 12, 24, 36)
    # Penyusutan per bulan = jumlah / durasi_bulan, berjalan sejak
    # tanggal_mulai sampai maksimal durasi_bulan (garis lurus / straight-line).
    add_column :financial_records, :jenis_akad, :string
    add_column :financial_records, :tanggal_mulai, :date
    add_column :financial_records, :durasi_bulan, :integer

    # 'prive' → uang yang DIAMBIL pemilik dari usaha (kebalikan dari
    # 'modal' yang uang masuk/disetor pemilik). Dipakai untuk menghitung
    # Modal Akhir di halaman "Modal Pemilik".
    # (kind masih kolom string bebas, tidak butuh migrasi kolom baru —
    # validasi inclusion-nya ada di model FinancialRecord::KINDS)
  end
end
