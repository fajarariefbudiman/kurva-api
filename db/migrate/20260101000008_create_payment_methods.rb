class CreatePaymentMethods < ActiveRecord::Migration[7.1]
  def change
    # Store user-specific payment methods; only cash transactions affect the physical cash drawer.
    create_table :payment_methods do |t|
      t.references :user, null: false, foreign_key: true
      t.string :nama, null: false           # nama tampilan, mis. "Transfer BCA"
      t.string :jenis, null: false           # tunai | transfer | qris | lainnya
      t.string :bank
      t.string :nomor_rekening
      t.string :atas_nama
      t.boolean :aktif, default: true, null: false
      t.timestamps
    end
    add_index :payment_methods, [:user_id, :aktif]
  end
end
