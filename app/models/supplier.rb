class Supplier < ApplicationRecord
  belongs_to :user
  has_many :purchases, dependent: :nullify

  validates :nama, presence: true
  validates :total_hutang, numericality: { greater_than_or_equal_to: 0 }
end
