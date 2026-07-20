class Customer < ApplicationRecord
  belongs_to :user
  has_many :transactions, dependent: :nullify

  validates :nama, presence: true
end
