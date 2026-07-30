class FinancialRecord < ApplicationRecord
  # Modal, Capex, Opex, Expense, Prive, dan Kas Masuk/Keluar semua
  # disimpan di sini, dibedakan lewat `kind`. COGS sengaja tidak ada di
  # sini karena dihitung otomatis dari transaksi penjualan (lihat
  # Reports::SummaryQuery).
  #   prive → uang yang DIAMBIL pemilik dari usaha (kebalikan dari
  #           'modal' yang uang disetor pemilik ke usaha). Dipakai untuk
  #           menghitung Modal Akhir di halaman "Modal Pemilik".
  #   pembelian_stok / bayar_hutang_supplier → kas keluar akibat beli
  #   atau melunasi hutang stok barang. SENGAJA dipisah dari `expense` /
  #   `kas_keluar` biasa: ini cuma perpindahan Kas -> Persediaan (atau
  #   pelunasan Hutang), BUKAN beban. Bebannya baru diakui sebagai COGS
  #   saat barangnya laku terjual (lihat Purchase & ReportsController).
  #   Karena itu kind ini ikut dihitung di laporan Arus Kas, tapi
  #   SENGAJA tidak ikut dijumlah ke total_expense di Laba Rugi, supaya
  #   tidak dobel-hitung dengan COGS.
  KINDS = %w[modal capex opex expense prive kas_masuk kas_keluar
             pembelian_stok bayar_hutang_supplier].freeze

  belongs_to :user
  belongs_to :cash_session, optional: true
  belongs_to :purchase, optional: true

  validates :kind, inclusion: { in: KINDS }
  validates :nama, presence: true
  validates :jumlah, numericality: { greater_than: 0 }
  validates :tanggal, presence: true
  validates :durasi_bulan, numericality: { greater_than: 0 }, allow_nil: true

  scope :of_kind, ->(k) { where(kind: k) }
  scope :in_range, ->(from, to) { where(tanggal: from..to) }

  # Penyusutan (depresiasi) garis lurus untuk kind: 'capex' yang punya
  # tanggal_mulai & durasi_bulan. Dipakai buat menghitung "Modal Akhir"
  # di halaman Modal Pemilik. Kalau capex-nya tidak diisi info amortisasi
  # (fitur ini opsional), dianggap belum ada penyusutan (0).
  def penyusutan_bulanan
    return 0 if durasi_bulan.to_i <= 0
    (jumlah / durasi_bulan).round(2)
  end

  def penyusutan_berjalan(as_of: Date.today)
    return 0 unless kind == "capex" && tanggal_mulai.present? && durasi_bulan.to_i > 0
    bulan_berjalan = ((as_of.year - tanggal_mulai.year) * 12 + (as_of.month - tanggal_mulai.month))
    bulan_berjalan += 1 if as_of.day >= tanggal_mulai.day
    bulan_berjalan = bulan_berjalan.clamp(0, durasi_bulan)
    (penyusutan_bulanan * bulan_berjalan).round(2)
  end
end
