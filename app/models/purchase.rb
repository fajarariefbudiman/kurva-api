# Pembelian/restock barang dari supplier. Kebalikan dari `Transaction`
# (penjualan), tapi efeknya BUKAN kebalikan dari sisi akuntansi:
#
#   - Penjualan: stok TURUN, dan porsi modalnya diakui sebagai COGS
#     saat itu juga (lihat Transaction#apply_side_effects!).
#   - Pembelian: stok NAIK, tapi TIDAK ada beban/expense yang diakui
#     sekarang. Uang yang keluar cuma pindah dari Kas -> Persediaan
#     (aset ke aset), bukan Kas -> Beban. Beban (COGS) baru muncul
#     nanti, sedikit demi sedikit, waktu barang ini terjual — via
#     snapshot `harga_modal` yang di-update di sini pakai weighted
#     average cost, lalu dipakai ulang oleh TransactionItem saat laku.
#
# Kalau status_pembayaran == "hutang", belum ada kas yang keluar sama
# sekali (nambah hutang usaha ke supplier), jadi juga belum boleh
# tercatat sebagai arus kas. Baru saat `lunasi_hutang!` dipanggil, kas
# keluar dicatat dan hutang berkurang.
class Purchase < ApplicationRecord
  STATUS_PEMBAYARAN = %w[lunas hutang].freeze
  METODE_PEMBAYARAN = %w[tunai transfer qris lainnya].freeze

  belongs_to :user
  belongs_to :supplier, optional: true
  has_many :purchase_items, dependent: :destroy, inverse_of: :purchase
  accepts_nested_attributes_for :purchase_items

  validates :penerima, presence: true
  validates :subtotal, :total, numericality: { greater_than_or_equal_to: 0 }
  validates :status_pembayaran, inclusion: { in: STATUS_PEMBAYARAN }
  validates :metode_pembayaran, inclusion: { in: METODE_PEMBAYARAN }, allow_nil: true
  validates :terjadi_pada, presence: true
  validate :harus_ada_item

  after_create :apply_side_effects!

  # Total nilai barang yang dibeli (buat ditampilkan di UI/laporan
  # pembelian; TIDAK dipakai sebagai expense di Laba Rugi).
  def total_pembelian
    purchase_items.sum { |i| i.harga_beli * i.qty }
  end

  # Dipanggil dari controller ketika hutang ke supplier dilunasi.
  # Baru DI SINI kas keluar benar-benar dicatat.
  def lunasi_hutang!
    return false unless status_pembayaran == "hutang"

    ActiveRecord::Base.transaction do
      supplier&.decrement!(:total_hutang, total)
      catat_kas_keluar!(kind: "bayar_hutang_supplier",
                         nama: "Pelunasan hutang#{" - #{supplier.nama}" if supplier}")
      update!(status_pembayaran: "lunas")
    end
    true
  end

  private

  def harus_ada_item
    errors.add(:purchase_items, "minimal 1 barang") if purchase_items.reject(&:marked_for_destruction?).empty?
  end

  # Efek samping wajib saat pembelian dibuat: naikkan stok & perbarui
  # harga modal (weighted average cost) tiap produk, lalu catat efek
  # kas/hutang sesuai status_pembayaran. Dibungkus satu transaction DB
  # supaya konsisten (semua berhasil, atau semua batal).
  def apply_side_effects!
    ActiveRecord::Base.transaction do
      purchase_items.each { |item| update_stock_and_cost!(item) }
      handle_payment_and_debt!
    end
  end

  def update_stock_and_cost!(item)
    product = item.product
    return unless product

    stok_lama = product.stok
    modal_lama = product.harga_modal
    stok_baru = stok_lama + item.qty

    modal_baru = stok_baru.zero? ? modal_lama : ((stok_lama * modal_lama) + (item.qty * item.harga_beli)) / stok_baru.to_f

    product.update!(stok: stok_baru, harga_modal: modal_baru.round(2))
  end

  def handle_payment_and_debt!
    case status_pembayaran
    when "lunas"
      catat_kas_keluar!(kind: "pembelian_stok",
                         nama: "Pembelian stok#{" - #{no_faktur}" if no_faktur.present?}")
    when "hutang"
      supplier&.increment!(:total_hutang, total)
    end
  end

  # Catatan kas TIDAK pernah dianggap sebagai expense/opex di Laba
  # Rugi (lihat ReportsController) — cuma dipakai buat laporan Arus
  # Kas, supaya tidak dobel-hitung dengan COGS yang muncul belakangan
  # saat barang laku.
  def catat_kas_keluar!(kind:, nama:)
    FinancialRecord.create!(
      user: user,
      purchase: self,
      kind: kind,
      nama: nama.presence || "Pembelian stok",
      jumlah: total,
      tanggal: terjadi_pada.to_date
    )
  end
end
