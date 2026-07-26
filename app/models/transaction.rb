# NB: nama kelas `Transaction` sengaja dipakai (transaksi PENJUALAN),
# bukan `ActiveRecord`-internal `Transaction` (namespace berbeda, tidak bentrok).
class Transaction < ApplicationRecord
  METODE_PEMBAYARAN = %w[tunai transfer qris lainnya].freeze

  belongs_to :user
  belongs_to :customer, optional: true
  belongs_to :cash_session, optional: true
  belongs_to :payment_method, optional: true
  has_many :transaction_items, dependent: :destroy, inverse_of: :sale
  accepts_nested_attributes_for :transaction_items

  validates :kasir, presence: true
  validates :subtotal, :total, numericality: { greater_than_or_equal_to: 0 }
  validates :metode_pembayaran, inclusion: { in: METODE_PEMBAYARAN }
  validates :terjadi_pada, presence: true

  after_create :apply_side_effects!

  def total_hpp
    transaction_items.sum { |i| i.harga_modal * i.qty }
  end

  private

  # Efek samping yang wajib terjadi bersamaan dengan penjualan:
  # kurangi stok produk & perbarui statistik pelanggan. Dibungkus satu
  # transaction DB supaya konsisten (semua berhasil, atau semua batal).
  def apply_side_effects!
    ActiveRecord::Base.transaction do
      transaction_items.each do |item|
        item.product&.decrement!(:stok, item.qty)
      end

      if customer
        customer.update!(
          total_belanja: customer.total_belanja + total,
          terakhir_belanja: terjadi_pada
        )
      end
    end
  end
end