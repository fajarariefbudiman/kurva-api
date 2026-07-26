class User < ApplicationRecord
  has_secure_password

  has_many :products, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :transactions, dependent: :destroy
  has_many :cash_sessions, dependent: :destroy
  has_many :financial_records, dependent: :destroy
  has_many :payment_methods, dependent: :destroy

  before_validation { self.email = email.to_s.downcase.strip }

  validates :nama_toko, presence: true
  validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "tidak valid" }
  validates :password, length: { minimum: 6 }, allow_nil: true

  def issue_token
    JsonWebToken.encode(user_id: id)
  end
end
