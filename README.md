# Kurva API

Ruby on Rails API for Kurva, a point-of-sale and financial management app for small businesses. It supports authentication, products, sales, cash sessions, and financial records.

## Architecture

- **Financial records:** The `financial_records` table stores `modal`, `capex`, `opex`, `expense`, `kas_masuk`, and `kas_keluar`, distinguished by `kind`.
- **COGS:** Calculated from `transaction_items.harga_modal * qty` instead of being recorded manually.
- **Data isolation:** Resource queries are scoped to the authenticated user, such as `current_user.products`.

## Requirements

- Ruby 3.2+
- PostgreSQL 14+
- Bundler (`gem install bundler`)

## Local Development

```bash
cd kurva_api
cp .env.example .env
bin/setup
bin/rails db:seed # Optional demo data
bin/rails server
```

The API runs at `http://localhost:3000`. The optional seed includes `demo@kurva.app` with password `password123`.

## Security

| Component | Purpose |
| --- | --- |
| `Rack::Attack` | Rate limits: 300 requests/5 min per IP, 5 logins/min per IP and email, 10 registrations/hour per IP. |
| `Rack::Cors` | Controls browser access using `CORS_ALLOWED_ORIGINS`. |
| `SecurityHeaders` | Adds response security headers. |
| `force_ssl` | Enforces HTTPS in production. |
| JWT | Authenticates requests using bearer tokens. |
| `bcrypt` | Hashes passwords using `has_secure_password`. |
| Filtered logging | Redacts passwords and tokens from logs. |

## API Reference

All responses use JSON. Except for registration and login, endpoints require `Authorization: Bearer <token>`.

### Authentication

```bash
# Register
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"user":{"nama_toko":"Warung Bu Sri","email":"sri@example.com","password":"password123","password_confirmation":"password123"}}'

# Login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"sri@example.com","password":"password123"}'

# Current user
curl http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer <token>"
```

### Products

```bash
# List products
curl http://localhost:3000/api/v1/products \
  -H "Authorization: Bearer <token>"

# Create a product
curl -X POST http://localhost:3000/api/v1/products \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"product":{"nama":"Es Teh","kategori":"Minuman","harga_jual":5000,"harga_modal":2000,"stok":50}}'
```

### Transactions

```bash
# Record a sale
curl -X POST http://localhost:3000/api/v1/transactions \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"transaction":{"kasir":"Kasir 1","subtotal":5000,"diskon":0,"total":5000,"metode_pembayaran":"tunai","uang_diterima":10000,"kembalian":5000,"items":[{"product_id":1,"nama":"Es Teh","harga":5000,"harga_modal":2000,"qty":1}]}}'
```

### Cash Sessions

```bash
# Open a session
curl -X POST http://localhost:3000/api/v1/cash_sessions \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"kasir":"Kasir 1","modal_awal":100000}'

# Get the active session
curl http://localhost:3000/api/v1/cash_sessions/active \
  -H "Authorization: Bearer <token>"

# Close a session
curl -X PATCH http://localhost:3000/api/v1/cash_sessions/1/close \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"kas_akhir_fisik":150000,"catatan":"Sesuai"}'
```

### Financial Records

Valid `kind` values: `modal`, `capex`, `opex`, `expense`, `kas_masuk`, and `kas_keluar`.

```bash
# Create a financial record
curl -X POST http://localhost:3000/api/v1/financial_records \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"financial_record":{"kind":"capex","nama":"Gerobak jualan","kategori":"Peralatan","jumlah":3000000,"tanggal":"2026-01-01"}}'

# Filter financial records
curl 'http://localhost:3000/api/v1/financial_records?kind=opex' \
  -H "Authorization: Bearer <token>"
```

### Reports

```bash
# Get a summary report
curl 'http://localhost:3000/api/v1/reports/summary?from=2026-07-01&to=2026-07-31' \
  -H "Authorization: Bearer <token>"
```

Example response:

```json
{
  "periode": { "dari": "2026-07-01", "sampai": "2026-07-31" },
  "penjualan": {
    "total_pendapatan": 1500000,
    "jumlah_transaksi": 42,
    "total_cogs": 600000,
    "laba_kotor": 900000
  },
  "keuangan": {
    "modal": 5000000,
    "capex": 3000000,
    "opex": 500000,
    "expense": 120000
  }
}
```

## Railway Deployment

1. Push the Rails project to GitHub and create a Railway project from the repository.
2. Add a PostgreSQL service and configure the Rails service to use its `DATABASE_URL`.
3. Set the following environment variables:

   | Variable | Value |
   | --- | --- |
   | `RAILS_ENV` | `production` |
   | `RAILS_MASTER_KEY` or `SECRET_KEY_BASE` | Rails secret or a generated secret, as required by the app configuration |
   | `JWT_SECRET` | A separate, randomly generated secret |
   | `CORS_ALLOWED_ORIGINS` | Allowed browser origins |
   | `RAILS_LOG_LEVEL` | `info` |
   | `WEB_CONCURRENCY` | `1` initially |

4. Deploy using the included `Gemfile`, `Procfile`, and `railway.toml` configuration.
5. Run migrations if they are not executed by the release command:

   ```bash
   bundle exec rails db:migrate
   bundle exec rails db:seed # Optional demo data
   ```

6. Check `GET /up` to verify the deployment.
7. Configure the API URL in the Flutter app:

   ```dart
   static const String baseUrl = String.fromEnvironment(
     'API_BASE_URL',
     defaultValue: 'https://kurva-api-production.up.railway.app',
   );
   ```

   Or provide it at build time:

   ```bash
   flutter build apk --dart-define=API_BASE_URL=https://kurva-api-production.up.railway.app
   ```

8. Optionally configure a custom domain in Railway networking settings.

Railway redeploys when changes are pushed to the connected branch. Database migrations depend on the configured release command.

## Tests

```bash
bin/rails db:test:prepare
bundle exec rspec
```

## Project Structure

```text
app/
  controllers/api/v1/  # API endpoints
  models/              # Domain models
config/
  initializers/        # CORS, rate limits, and security headers
  environments/        # Environment configuration
db/migrate/             # Database migrations
lib/json_web_token.rb  # JWT utilities
railway.toml           # Railway deployment settings
Procfile               # Process commands
```
