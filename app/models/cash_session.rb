class CashSession < ApplicationRecord
  belongs_to :user
  has_many :transactions, dependent: :nullify
  has_many :financial_records, dependent: :nullify

  validates :kasir, presence: true
  validates :modal_awal, numericality: { greater_than_or_equal_to: 0 }

  scope :open_session, -> { where(ditutup_pada: nil) }

  def open?
    ditutup_pada.nil?
  end

  # Gross profit equals total sales minus COGS at session close.
  def laba_kotor
    (total_penjualan || 0) - (total_hpp || 0)
  end
end
