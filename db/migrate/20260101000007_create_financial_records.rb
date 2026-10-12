class CreateFinancialRecords < ActiveRecord::Migration[7.1]
  def change
    # Store owner capital, capex, opex, expenses, and cash movements by `kind`.
    # Calculate COGS from transaction item quantities and unit costs.
    create_table :financial_records do |t|
      t.references :user, null: false, foreign_key: true
      t.references :cash_session, foreign_key: true
      t.string :kind, null: false
      t.string :nama, null: false
      t.string :kategori
      t.decimal :jumlah, precision: 14, scale: 2, null: false
      t.date :tanggal, null: false
      t.boolean :berulang, default: false # dipakai khusus kind: opex
      t.text :catatan
      t.timestamps
    end
    add_index :financial_records, [:user_id, :kind, :tanggal]
  end
end
