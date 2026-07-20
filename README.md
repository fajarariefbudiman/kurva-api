# Kurva API

Backend Ruby on Rails (mode API-only) untuk aplikasi Kurva — kasir digital
UMKM. Menangani autentikasi (Login/Register), produk, transaksi, sesi kas,
dan pencatatan keuangan (Modal, Capex, Opex, COGS, Expense, Kas Masuk/Keluar).

## Kenapa strukturnya begini

- **Satu tabel `financial_records` untuk 6 jenis catatan** (Modal, Capex,
  Opex, Expense, Kas Masuk, Kas Keluar), dibedakan lewat kolom `kind`.
  Ini disengaja: kelimanya punya bentuk data yang identik (nama, jumlah,
  tanggal, kategori), jadi satu tabel lebih gampang di-maintain daripada
  lima tabel yang isinya sama persis.
- **COGS/HPP tidak disimpan manual** — dihitung otomatis dari
  `transaction_items.harga_modal x qty` tiap kali laporan diminta. Ini
  memastikan HPP selalu konsisten dengan transaksi yang benar-benar
  terjadi, tidak bisa "lupa dicatat" seperti kalau manual.
- **Multi-tenant per `user`** — tiap toko yang daftar (`User`) hanya bisa
  melihat & mengubah data miliknya sendiri. Semua controller resource
  query lewat `current_user.products`, dst, jadi tidak mungkin bocor ke
  toko lain.

## Kebutuhan sistem

- Ruby 3.2+
- PostgreSQL 14+
- Bundler (`gem install bundler`)

## Setup development lokal

```bash
cd kurva_api
cp .env.example .env
# edit .env: isi DATABASE_URL sesuai Postgres lokal kamu,
# lalu generate SECRET_KEY_BASE & JWT_SECRET dengan:
#   ruby -rsecurerandom -e "puts SecureRandom.hex(64)"

bin/setup          # bundle install + siapkan database
bin/rails db:seed  # (opsional) isi data contoh — akun demo@kurva.app / password123
bin/rails server   # jalan di http://localhost:3000
```

## Middleware & keamanan yang sudah aktif

| Middleware | Fungsi |
|---|---|
| `Rack::Attack` | Rate limiting: 300 request/5 menit per IP (umum), 5 percobaan login/menit per IP+email, 10 registrasi/jam per IP |
| `Rack::Cors` | Mengizinkan app Flutter (atau domain lain via `CORS_ALLOWED_ORIGINS`) memanggil API |
| `SecurityHeaders` (custom) | `X-Content-Type-Options`, `X-Frame-Options`, `Content-Security-Policy`, dll di tiap response |
| `force_ssl` (production) | Memaksa semua trafik production lewat HTTPS |
| JWT (`Authorization: Bearer <token>`) | Autentikasi tanpa session/cookie, cocok untuk mobile app |
| `bcrypt` (`has_secure_password`) | Password di-hash, tidak pernah disimpan plain text |
| Filtered logging | `password` & `token` otomatis disamarkan di log server |

## Referensi endpoint

Semua response JSON. Endpoint selain `auth/register` & `auth/login` wajib
header `Authorization: Bearer <token>`.

### Auth

```bash
# Daftar toko baru
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"user":{"nama_toko":"Warung Bu Sri","email":"sri@contoh.com","password":"rahasia123","password_confirmation":"rahasia123"}}'
# → { "token": "...", "user": { "id": 1, "nama_toko": "...", "email": "..." } }

# Login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"sri@contoh.com","password":"rahasia123"}'

# Cek profil sendiri
curl http://localhost:3000/api/v1/auth/me -H "Authorization: Bearer <token>"
```

### Produk

```bash
curl http://localhost:3000/api/v1/products -H "Authorization: Bearer <token>"

curl -X POST http://localhost:3000/api/v1/products \
  -H "Authorization: Bearer <token>" -H "Content-Type: application/json" \
  -d '{"product":{"nama":"Es Teh","kategori":"Minuman","harga_jual":5000,"harga_modal":2000,"stok":50}}'
```

### Transaksi (penjualan)

```bash
curl -X POST http://localhost:3000/api/v1/transactions \
  -H "Authorization: Bearer <token>" -H "Content-Type: application/json" \
  -d '{"transaction":{
        "kasir":"Kasir 1","subtotal":5000,"diskon":0,"total":5000,
        "metode_pembayaran":"tunai","uang_diterima":10000,"kembalian":5000,
        "items":[{"product_id":1,"nama":"Es Teh","harga":5000,"harga_modal":2000,"qty":1}]
      }}'
```

### Sesi kas (buka/tutup)

```bash
curl -X POST http://localhost:3000/api/v1/cash_sessions \
  -H "Authorization: Bearer <token>" -H "Content-Type: application/json" \
  -d '{"kasir":"Kasir 1","modal_awal":100000}'

curl http://localhost:3000/api/v1/cash_sessions/active -H "Authorization: Bearer <token>"

curl -X PATCH http://localhost:3000/api/v1/cash_sessions/1/close \
  -H "Authorization: Bearer <token>" -H "Content-Type: application/json" \
  -d '{"kas_akhir_fisik":150000,"catatan":"Sesuai"}'
```

### Keuangan — Modal, Capex, Opex, Expense, Kas Masuk/Keluar

`kind` wajib salah satu dari: `modal`, `capex`, `opex`, `expense`,
`kas_masuk`, `kas_keluar`.

```bash
curl -X POST http://localhost:3000/api/v1/financial_records \
  -H "Authorization: Bearer <token>" -H "Content-Type: application/json" \
  -d '{"financial_record":{"kind":"capex","nama":"Gerobak jualan","kategori":"Peralatan","jumlah":3000000,"tanggal":"2026-01-01"}}'

curl "http://localhost:3000/api/v1/financial_records?kind=opex" -H "Authorization: Bearer <token>"
```

### Laporan ringkas

```bash
curl "http://localhost:3000/api/v1/reports/summary?from=2026-07-01&to=2026-07-31" \
  -H "Authorization: Bearer <token>"
```

```json
{
  "periode": { "dari": "2026-07-01", "sampai": "2026-07-31" },
  "penjualan": { "total_pendapatan": 1500000, "jumlah_transaksi": 42, "total_cogs": 600000, "laba_kotor": 900000 },
  "keuangan": { "modal": 5000000, "capex": 3000000, "opex": 500000, "expense": 120000 }
}
```

## Deploy ke Railway

1. **Buat project baru di Railway** → *New Project* → *Deploy from GitHub repo*
   (push folder `kurva_api` ini ke repo GitHub terlebih dahulu).

2. **Tambahkan database Postgres**: di dalam project, klik *New* →
   *Database* → *Add PostgreSQL*. Railway otomatis membuat variabel
   `DATABASE_URL` dan menyambungkannya ke service Rails kamu — tidak perlu
   diisi manual.

3. **Set environment variables** pada service Rails (tab *Variables*):

   | Key | Value |
   |---|---|
   | `RAILS_ENV` | `production` |
   | `RAILS_MASTER_KEY` atau `SECRET_KEY_BASE` | hasil dari `ruby -rsecurerandom -e "puts SecureRandom.hex(64)"` |
   | `JWT_SECRET` | hasil dari perintah yang sama (pakai nilai berbeda) |
   | `CORS_ALLOWED_ORIGINS` | domain yang boleh akses, atau `*` untuk mobile app |
   | `RAILS_LOG_LEVEL` | `info` |
   | `WEB_CONCURRENCY` | `1` (naikkan kalau butuh lebih banyak worker) |

4. **Railway otomatis mendeteksi Rails** lewat Nixpacks berkat `Gemfile`,
   `Procfile`, dan `railway.toml` yang sudah disertakan. Build & deploy
   akan otomatis jalan setiap push ke branch yang di-deploy.

5. **Migrasi database berjalan otomatis** lewat baris `release:` di
   `Procfile` (`bundle exec rails db:migrate`) setiap kali deploy sukses.
   Untuk migrasi manual (mis. deploy pertama kali), buka tab *Shell* di
   Railway lalu jalankan:
   ```bash
   bundle exec rails db:migrate
   bundle exec rails db:seed   # opsional, isi akun demo
   ```

6. **Cek health check**: Railway akan memantau `GET /up` (dikonfigurasi di
   `railway.toml`). Kalau endpoint ini merespons 200, deploy dianggap
   berhasil.

7. **Catat domain publik**-nya (mis. `https://kurva-api-production.up.railway.app`)
   dan masukkan ke `lib/services/api_config.dart` di app Flutter:
   ```dart
   static const String baseUrl = String.fromEnvironment(
     'API_BASE_URL',
     defaultValue: 'https://kurva-api-production.up.railway.app',
   );
   ```
   atau jalankan build Flutter dengan:
   ```bash
   flutter build apk --dart-define=API_BASE_URL=https://kurva-api-production.up.railway.app
   ```

8. **(Opsional) Custom domain**: tab *Settings* → *Networking* → *Custom
   Domain* di service Rails, lalu tambahkan CNAME sesuai instruksi Railway.

### Redeploy setelah ubah kode

Railway otomatis redeploy tiap kali kamu push ke branch yang terhubung.
Tidak perlu langkah manual tambahan — migrasi baru akan otomatis jalan
lewat `release:` command di atas.

## Menjalankan test (opsional, RSpec sudah disiapkan di Gemfile)

```bash
bin/rails db:test:prepare
bundle exec rspec
```

## Struktur folder singkat

```
app/
  controllers/api/v1/   # semua endpoint /api/v1/*
  models/                # User, Product, Customer, Transaction,
                          # TransactionItem, CashSession, FinancialRecord
config/
  initializers/cors.rb           # CORS
  initializers/rack_attack.rb    # rate limiting
  initializers/security_headers.rb
  environments/production.rb     # force_ssl, logging ke stdout, dll
db/migrate/               # migrasi database
lib/json_web_token.rb     # encode/decode token JWT
railway.toml, Procfile    # konfigurasi deploy Railway
```
