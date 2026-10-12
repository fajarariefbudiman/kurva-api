# Purchases increase stock and inventory value; COGS is recognized only when items are sold.
# Credit purchases incur supplier debt; cash outflow is recorded upon settlement.
class Purchase < ApplicationRecord
  STATUS_PEMBAYARAN = %w[lunas hutang].freeze
  METODE_PEMBAYARAN = %w[tunai transfer qris lainnya].freeze

  # Register this callback before dependent item deletion so original items remain available.
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

  # Inventory purchase value is not a profit-and-loss expense.
  def total_pembelian
    purchase_items.sum { |i| i.harga_beli * i.qty }
  end

  # Record cash outflow only when supplier debt is settled.
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

  # Atomically update stock, weighted-average unit cost, and cash or supplier debt on purchase creation.
  # Also apply these effects after updates once prior effects have been reversed.
  def apply_side_effects!
    ActiveRecord::Base.transaction do
      purchase_items.each { |item| update_stock_and_cost!(item) }
      handle_payment_and_debt!
    end
  end

  # Reverse original purchase side effects before editing or deleting a purchase.
  # Weighted-average cost cannot always be reversed exactly after later stock movements; prevent negative stock.
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

  # Reverse the stock and cost update where mathematically possible.
  def reverse_stock_and_cost!(item)
    product = item.product
    return unless product

    stok_lama = product.stok
    modal_lama = product.harga_modal
    stok_baru = stok_lama - item.qty

    if stok_baru <= 0
      # Prevent negative stock when exact cost reversal is impossible.
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

  # Reverse purchase cash entries and any outstanding supplier debt.
  def reverse_payment_and_debt!
    financial_records.destroy_all
    supplier&.decrement!(:total_hutang, total) if status_pembayaran == "hutang"
  end

  # Treat inventory cash movements as cash flow, not profit-and-loss expense, to avoid duplicate COGS.
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
