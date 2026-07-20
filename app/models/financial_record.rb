class FinancialRecord < ApplicationRecord
  # Modal, Capex, Opex, Expense, dan Kas Masuk/Keluar semua disimpan di
  # sini, dibedakan lewat `kind`. COGS sengaja tidak ada di sini karena
  # dihitung otomatis dari transaksi penjualan (lihat Reports::SummaryQuery).
  KINDS = %w[modal capex opex expense kas_masuk kas_keluar].freeze

  belongs_to :user
  belongs_to :cash_session, optional: true

  validates :kind, inclusion: { in: KINDS }
  validates :nama, presence: true
  validates :jumlah, numericality: { greater_than: 0 }
  validates :tanggal, presence: true

  scope :of_kind, ->(k) { where(kind: k) }
  scope :in_range, ->(from, to) { where(tanggal: from..to) }
end
