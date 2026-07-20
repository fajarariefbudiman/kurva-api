# This file is auto-generated from the current state of the database.
# After running `rails db:migrate`, Rails will regenerate this file to match.
ActiveRecord::Schema[7.1].define(version: 2026_01_01_000007) do
  enable_extension "plpgsql"

  create_table "cash_sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "kasir", null: false
    t.datetime "dibuka_pada", null: false
    t.decimal "modal_awal", precision: 14, scale: 2, null: false
    t.datetime "ditutup_pada"
    t.decimal "total_penjualan", precision: 14, scale: 2
    t.decimal "total_tunai", precision: 14, scale: 2
    t.decimal "total_non_tunai", precision: 14, scale: 2
    t.decimal "total_hpp", precision: 14, scale: 2
    t.decimal "kas_akhir_sistem", precision: 14, scale: 2
    t.decimal "kas_akhir_fisik", precision: 14, scale: 2
    t.decimal "selisih_kas", precision: 14, scale: 2
    t.integer "jumlah_transaksi"
    t.text "catatan"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_cash_sessions_on_user_id"
  end

  create_table "customers", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "nama", null: false
    t.string "hp"
    t.decimal "total_belanja", precision: 14, scale: 2, default: "0.0", null: false
    t.datetime "terakhir_belanja"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_customers_on_user_id"
  end

  create_table "financial_records", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "cash_session_id"
    t.string "kind", null: false
    t.string "nama", null: false
    t.string "kategori"
    t.decimal "jumlah", precision: 14, scale: 2, null: false
    t.date "tanggal", null: false
    t.boolean "berulang", default: false
    t.text "catatan"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cash_session_id"], name: "index_financial_records_on_cash_session_id"
    t.index ["user_id", "kind", "tanggal"], name: "index_financial_records_on_user_id_and_kind_and_tanggal"
  end

  create_table "products", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "nama", null: false
    t.string "kategori", default: "Umum", null: false
    t.decimal "harga_jual", precision: 14, scale: 2, default: "0.0", null: false
    t.decimal "harga_modal", precision: 14, scale: 2, default: "0.0", null: false
    t.integer "stok", default: 0, null: false
    t.string "foto_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "nama"], name: "index_products_on_user_id_and_nama"
  end

  create_table "transaction_items", force: :cascade do |t|
    t.bigint "transaction_id", null: false
    t.bigint "product_id"
    t.string "nama", null: false
    t.decimal "harga", precision: 14, scale: 2, null: false
    t.decimal "harga_modal", precision: 14, scale: 2, default: "0.0", null: false
    t.integer "qty", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_transaction_items_on_product_id"
    t.index ["transaction_id"], name: "index_transaction_items_on_transaction_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "customer_id"
    t.bigint "cash_session_id"
    t.string "kasir", null: false
    t.decimal "subtotal", precision: 14, scale: 2, null: false
    t.decimal "diskon", precision: 14, scale: 2, default: "0.0", null: false
    t.decimal "total", precision: 14, scale: 2, null: false
    t.string "metode_pembayaran", null: false
    t.decimal "uang_diterima", precision: 14, scale: 2
    t.decimal "kembalian", precision: 14, scale: 2
    t.datetime "terjadi_pada", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cash_session_id"], name: "index_transactions_on_cash_session_id"
    t.index ["customer_id"], name: "index_transactions_on_customer_id"
    t.index ["user_id", "terjadi_pada"], name: "index_transactions_on_user_id_and_terjadi_pada"
  end

  create_table "users", force: :cascade do |t|
    t.string "nama_toko", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "hp_toko"
    t.string "alamat"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "cash_sessions", "users"
  add_foreign_key "customers", "users"
  add_foreign_key "financial_records", "cash_sessions"
  add_foreign_key "financial_records", "users"
  add_foreign_key "products", "users"
  add_foreign_key "transaction_items", "products"
  add_foreign_key "transaction_items", "transactions"
  add_foreign_key "transactions", "cash_sessions"
  add_foreign_key "transactions", "customers"
  add_foreign_key "transactions", "users"
end
