class FinancialRecord < ApplicationRecord
  # Track financial records by `kind`; calculate sales COGS separately from transaction items.
  # Owner withdrawals (`prive`) reduce ending owner equity.
  # Inventory purchases and supplier repayments affect cash flow, not operating expenses.
  # Exclude inventory cash movements from expenses to avoid double-counting COGS.
  KINDS = %w[modal capex opex expense prive kas_masuk kas_keluar
             pembelian_stok bayar_hutang_supplier].freeze

  belongs_to :user
  belongs_to :cash_session, optional: true
  belongs_to :purchase, optional: true

  validates :kind, inclusion: { in: KINDS }
  validates :nama, presence: true
  validates :jumlah, numericality: { greater_than: 0 }
  validates :tanggal, presence: true
  validates :durasi_bulan, numericality: { greater_than: 0 }, allow_nil: true

  scope :of_kind, ->(k) { where(kind: k) }
  scope :in_range, ->(from, to) { where(tanggal: from..to) }

  # Calculate optional straight-line depreciation for capital assets with a start date and duration.
  def penyusutan_bulanan
    return 0 if durasi_bulan.to_i <= 0
    (jumlah / durasi_bulan).round(2)
  end

  def penyusutan_berjalan(as_of: Date.today)
    return 0 unless kind == "capex" && tanggal_mulai.present? && durasi_bulan.to_i > 0
    bulan_berjalan = ((as_of.year - tanggal_mulai.year) * 12 + (as_of.month - tanggal_mulai.month))
    bulan_berjalan += 1 if as_of.day >= tanggal_mulai.day
    bulan_berjalan = bulan_berjalan.clamp(0, durasi_bulan)
    (penyusutan_bulanan * bulan_berjalan).round(2)
  end
end
