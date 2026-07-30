class CreateSuppliers < ActiveRecord::Migration[7.1]
  def change
    create_table :suppliers do |t|
      t.references :user, null: false, foreign_key: true
      t.string :nama, null: false
      t.string :hp
      t.string :alamat
      t.decimal :total_hutang, precision: 14, scale: 2, null: false, default: 0
      t.timestamps
    end
    add_index :suppliers, [:user_id, :nama]
  end
end
