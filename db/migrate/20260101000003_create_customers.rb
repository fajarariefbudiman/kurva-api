class CreateCustomers < ActiveRecord::Migration[7.1]
  def change
    create_table :customers do |t|
      t.references :user, null: false, foreign_key: true
      t.string :nama, null: false
      t.string :hp
      t.decimal :total_belanja, precision: 14, scale: 2, null: false, default: 0
      t.datetime :terakhir_belanja
      t.timestamps
    end
  end
end
