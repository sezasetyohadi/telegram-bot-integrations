# Telegram Bot Integration

Bot Telegram untuk sistem verifikasi dan notifikasi otomatis dengan integrasi database Supabase.

## Fitur

- ✅ Sistem verifikasi user dengan username dan role
- 🔐 Manajemen role (admin/waspang)
- 📱 Notifikasi otomatis via Telegram
- 🚫 Sistem penalty untuk failed attempts
- 🛡️ Pencegahan spam dan duplikasi pesan
- 📊 Integrasi database Supabase

## Teknologi

- **Node.js** - Runtime environment
- **TypeScript** - Programming language
- **Telegraf** - Telegram bot framework
- **Supabase** - Database dan backend
- **Express.js** - Web server untuk API
- **node-cron** - Task scheduling

## Setup

1. Clone repository:
```bash
git clone https://github.com/sezasetyohadi/telegram-bot-integration.git
cd telegram-bot-integration
```

2. Install dependencies:
```bash
npm install
```

3. Setup environment variables (.env):
```env
TELEGRAM_BOT_TOKEN=your_telegram_bot_token
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

4. Build project:
```bash
npm run build
```

5. Start application:
```bash
npm start
```

## Struktur Database

### Tabel `user_roles`
- `id` (PRIMARY KEY)
- `user_name` (VARCHAR)
- `role_id` (INTEGER) - 1: admin, 2: waspang
- `telegram_id` (BIGINT) - ID Telegram user

### Tabel `notifications`
- `id` (PRIMARY KEY)
- `user_id` (VARCHAR/INTEGER)
- `message` (TEXT)
- `created_at` (TIMESTAMP)
- `sent` (BOOLEAN) - default: false

## Commands

- `/start` - Mulai proses verifikasi
- `/menu` - Tampilkan menu utama

## API Endpoints

- `POST /api/telegram-notify` - Kirim notifikasi
- `GET /health` - Health check

## Security Features

- Message deduplication
- Update ID tracking
- Rate limiting dengan penalty system
- Input validation

## Development

```bash
# Development mode
npm run dev

# Build
npm run build

# Production
npm start
```

## Contributing

1. Fork repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## License

MIT License
