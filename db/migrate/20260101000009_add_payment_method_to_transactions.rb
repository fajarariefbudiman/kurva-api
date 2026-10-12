class AddPaymentMethodToTransactions < ActiveRecord::Migration[7.1]
  def change
    # Optional payment-method relation defaults to cash when unconfigured.
    # Keep a receipt label snapshot when payment methods are later edited or removed.
    # Use the existing payment category to calculate physical cash at session close.
    add_reference :transactions, :payment_method, foreign_key: true, null: true
    add_column :transactions, :payment_method_label, :string
  end
end
