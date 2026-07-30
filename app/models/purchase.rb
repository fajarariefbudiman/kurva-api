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

  # PENTING: didaftarkan SEBELUM asosiasi `dependent: :destroy` di bawah.
  # Di Rails, urutan eksekusi callback `before_*` mengikuti urutan
  # PENDAFTARAN (top-to-bottom di file ini) — jadi callback ini WAJIB
  # duluan supaya reverse_side_effects! masih sempat baca purchase_items
  # yang lama sebelum keburu ikut terhapus oleh `dependent: :destroy`.
  before_destroy :reverse_side_effects!

  belongs_to :user
  belongs_to :supplier, optional: true
  has_many :purchase_items, dependent: :destroy, inverse_of: :purchase
  has_many :financial_records, dependent: :destroy
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

  # Efek samping wajib saat pembelian dibuat: naikkan stok & perbarui
  # harga modal (weighted average cost) tiap produk, lalu catat efek
  # kas/hutang sesuai status_pembayaran. Dibungkus satu transaction DB
  # supaya konsisten (semua berhasil, atau semua batal).
  #
  # Dipanggil otomatis via after_create, DAN dipanggil manual oleh
  # PurchasesController#update setelah data pembelian selesai diperbarui
  # (lihat reverse_side_effects! di bawah untuk arah sebaliknya).
  def apply_side_effects!
    ActiveRecord::Base.transaction do
      purchase_items.each { |item| update_stock_and_cost!(item) }
      handle_payment_and_debt!
    end
  end

  # Kebalikan dari apply_side_effects! — meng-"undo" efek stok/harga
  # modal produk serta kas/hutang, memakai data purchase_items & status
  # pembayaran yang MASIH LAMA (belum diubah). Dipanggil sebelum sebuah
  # pembelian diedit (lihat PurchasesController#update) atau dihapus
  # (before_destroy di atas).
  #
  # CATATAN keterbatasan: kalau stok produk sudah berkurang lagi setelah
  # pembelian ini (mis. karena sudah kejual), reversal harga modal tidak
  # bisa 100% presisi secara matematis (weighted average cost bukan
  # operasi yang bisa dibalik sempurna kalau ada pergerakan stok lain di
  # antaranya). Untuk kasus itu, stok diamankan supaya tidak sampai
  # minus, dan harga modal dibiarkan seperti sebelum reversal.
  def reverse_side_effects!
    ActiveRecord::Base.transaction do
      purchase_items.each { |item| reverse_stock_and_cost!(item) }
      reverse_payment_and_debt!
    end
  end

  private

  def harus_ada_item
    errors.add(:purchase_items, "minimal 1 barang") if purchase_items.reject(&:marked_for_destruction?).empty?
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

  # Kebalikan matematis dari update_stock_and_cost! di atas.
  def reverse_stock_and_cost!(item)
    product = item.product
    return unless product

    stok_lama = product.stok
    modal_lama = product.harga_modal
    stok_baru = stok_lama - item.qty

    if stok_baru <= 0
      # Tidak bisa dihitung mundur secara akurat (lihat catatan di
      # reverse_side_effects!) — amankan saja supaya stok tidak minus.
      product.update!(stok: 0)
    else
      total_modal_lama = stok_lama * modal_lama
      total_modal_item = item.qty * item.harga_beli
      modal_baru = (total_modal_lama - total_modal_item) / stok_baru.to_f
      product.update!(stok: stok_baru, harga_modal: [modal_baru, 0].max.round(2))
    end
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

  # Kebalikan dari handle_payment_and_debt! — hapus catatan kas keluar
  # yang terkait pembelian ini (baik yang dari pembelian lunas maupun
  # dari pelunasan hutang belakangan, lihat lunasi_hutang!), dan
  # kembalikan hutang supplier kalau pembelian ini masih berstatus
  # "hutang" (artinya belum pernah dilunasi, jadi hutangnya masih perlu
  # dibatalkan).
  def reverse_payment_and_debt!
    financial_records.destroy_all
    supplier&.decrement!(:total_hutang, total) if status_pembayaran == "hutang"
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
