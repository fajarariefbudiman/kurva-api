# Sales transaction model; separate from the ActiveRecord internal transaction class.
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

  # Atomically deduct inventory and update customer sales statistics.
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