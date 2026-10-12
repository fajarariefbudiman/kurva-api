# Sample development data; run with bin/rails db:seed.
user = User.find_or_create_by!(email: "demo@kurva.app") do |u|
  u.nama_toko = "Warung Demo"
  u.password = "password123"
  u.password_confirmation = "password123"
end

puts "User demo siap: #{user.email} / password123"

if user.products.none?
  user.products.create!([
    { nama: "Es Teh Manis", kategori: "Minuman", harga_jual: 5000, harga_modal: 2000, stok: 50 },
    { nama: "Nasi Goreng", kategori: "Makanan", harga_jual: 15000, harga_modal: 8000, stok: 30 }
  ])
  puts "2 produk contoh dibuat"
end

if user.payment_methods.none?
  user.payment_methods.create!([
    {
      nama: "Transfer JAGO",
      jenis: "transfer",
      bank: "JAGO",
      nomor_rekening: "190282918",
      atas_nama: "FAJAR ARIEF BUDIMAN",
      aktif: true
    }
  ])
  puts "Metode pembayaran transfer contoh dibuat (dipakai di invoice)"
end

if user.financial_records.none?
  user.financial_records.create!([
    { kind: "modal", nama: "Setoran modal awal", jumlah: 5_000_000, tanggal: 90.days.ago },
    {
      kind: "capex", nama: "Gerobak jualan", kategori: "Peralatan",
      jumlah: 3_000_000, tanggal: 89.days.ago,
      jenis_akad: "beli", tanggal_mulai: 89.days.ago.to_date, durasi_bulan: 36
    },
    { kind: "opex", nama: "Sewa tempat", kategori: "Sewa", jumlah: 500_000, tanggal: 5.days.ago, berulang: true },
    { kind: "prive", nama: "Ambil buat kebutuhan pribadi", jumlah: 200_000, tanggal: 3.days.ago }
  ])
  puts "Contoh catatan keuangan dibuat"
end
