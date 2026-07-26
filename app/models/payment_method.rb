class PaymentMethod < ApplicationRecord
  JENIS = %w[tunai transfer qris lainnya].freeze

  belongs_to :user
  has_many :transactions, dependent: :nullify

  validates :nama, presence: true
  validates :jenis, inclusion: { in: JENIS }

  # Label lengkap buat ditampilkan/disnapshot ke struk transaksi.
  def label
    if jenis == "transfer" && bank.present?
      parts = ["Transfer #{bank}"]
      parts << nomor_rekening if nomor_rekening.present?
      parts << "a.n #{atas_nama}" if atas_nama.present?
      parts.join(" - ")
    else
      nama
    end
  end
end
