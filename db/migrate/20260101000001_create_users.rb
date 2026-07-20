class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :nama_toko, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :hp_toko
      t.string :alamat
      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
