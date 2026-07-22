class TransactionItem < ApplicationRecord
  belongs_to :sale, class_name: "Transaction", foreign_key: "transaction_id"
  belongs_to :product, optional: true

  validates :nama, presence: true
  validates :harga, numericality: { greater_than_or_equal_to: 0 }
  validates :qty, numericality: { only_integer: true, greater_than: 0 }

  def subtotal
    harga * qty
  end

  def hpp
    harga_modal * qty
  end
end