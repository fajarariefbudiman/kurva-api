class AddPurchaseToFinancialRecords < ActiveRecord::Migration[7.1]
  def change
    add_reference :financial_records, :purchase, foreign_key: true
  end
end
