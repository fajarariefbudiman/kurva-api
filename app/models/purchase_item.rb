class PurchaseItem < ApplicationRecord
  belongs_to :purchase, inverse_of: :purchase_items
  belongs_to :product, optional: true

  validates :nama, presence: true
  validates :harga_beli, numericality: { greater_than_or_equal_to: 0 }
  validates :qty, numericality: { only_integer: true, greater_than: 0 }

  def subtotal
    harga_beli * qty
  end
end
