import { Telegraf, session } from 'telegraf';
import * as dotenv from 'dotenv';
import cron from 'node-cron';
import { handleStart } from './commands/start';
import { NotificationService } from './services/notification';

dotenv.config();

// Token bot HARUS dari environment variable
const bot = new Telegraf(process.env.TELEGRAM_BOT_TOKEN!);

// Pastikan bot tidak dijalankan multiple kali
let botStarted = false;

// Add session middleware
bot.use(session({
  defaultSession: () => ({})
}));

// Middleware untuk mencegah duplikasi update
const processedUpdates = new Set<number>();
bot.use((ctx, next) => {
  const updateId = ctx.update.update_id;
  
  if (processedUpdates.has(updateId)) {
    console.log(`⚠️ Duplicate update detected: ${updateId}`);
    return;
  }
  
  processedUpdates.add(updateId);
  
  // Bersihkan set jika terlalu besar
  if (processedUpdates.size > 1000) {
    const updates = Array.from(processedUpdates);
    processedUpdates.clear();
    updates.slice(-500).forEach(id => processedUpdates.add(id));
  }
  
  return next();
});

// Register commands
handleStart(bot);  // Pass bot instance to handleStart

console.log('✅ All command handlers registered');

// Add global error handler
bot.catch((err, ctx) => {
  console.error(`Error for ${ctx.updateType}:`, err);
  ctx.reply('❌ Terjadi kesalahan. Silakan coba lagi.');
});

// Jadwalkan pengecekan dan pengiriman notifikasi otomatis setiap 10 detik
let cronRunning = false;
cron.schedule('*/10 * * * * *', async () => {
  if (cronRunning) {
    console.log('⚠️ Previous cron job still running, skipping...');
    return;
  }
  
  cronRunning = true;
  try {
    const pendingCount = await NotificationService.checkPendingMessages();
    if (pendingCount > 0) {
      console.log(`🔔 Found ${pendingCount} pending notifications, processing...`);
      await NotificationService.processAndSendNotifications(bot.telegram);
    }
  } catch (error) {
    console.error('Auto notification error:', error);
  } finally {
    cronRunning = false;
  }
});

// Jalankan bot
if (!botStarted) {
  bot.launch()
    .then(() => {
      botStarted = true;
      console.log('🤖 Bot berjalan!');
    })
    .catch(err => console.error('💥 Gagal menjalankan bot:', err));
} else {
  console.log('⚠️ Bot sudah berjalan, skip launch');
}

// Handle shutdown
process.once('SIGINT', () => bot.stop('SIGINT'));
process.once('SIGTERM', () => bot.stop('SIGTERM'));