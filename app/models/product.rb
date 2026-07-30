class Product < ApplicationRecord
  belongs_to :user
  has_many :transaction_items, dependent: :nullify
  has_many :purchase_items, dependent: :nullify

  validates :nama, presence: true
  validates :kategori, presence: true
  validates :harga_jual, :harga_modal, numericality: { greater_than_or_equal_to: 0 }
  validates :stok, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
