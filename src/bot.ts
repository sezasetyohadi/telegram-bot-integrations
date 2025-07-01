import { Telegraf, session } from 'telegraf';
import * as dotenv from 'dotenv';
import cron from 'node-cron';
import { handleStart } from './commands/start';
import { NotificationService } from './services/notification';
import { VerificationManager } from './utils/verification';

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

// Middleware untuk validasi akses grup
bot.use(async (ctx, next) => {
  // Skip validasi untuk beberapa update type
  if (ctx.updateType === 'my_chat_member' || ctx.updateType === 'chat_member') {
    return next();
  }

  // Jika di grup, validasi akses
  if (ctx.chat?.type === 'group' || ctx.chat?.type === 'supergroup') {
    const hasAccess = await VerificationManager.validateAccess(ctx);
    
    if (!hasAccess) {
      await ctx.reply('❌ Hanya admin yang terdaftar yang dapat menggunakan bot ini di grup.');
      return;
    }
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

// Handle bot ditambahkan ke grup
bot.on('my_chat_member', async (ctx) => {
  const update = ctx.update.my_chat_member;
  const newStatus = update.new_chat_member.status;
  const oldStatus = update.old_chat_member.status;
  const addedBy = update.from;
  const groupId = ctx.chat.id;
  const groupTitle = (ctx.chat.type === 'group' || ctx.chat.type === 'supergroup') 
    ? ctx.chat.title || 'Unknown Group' 
    : 'Unknown Group';
  
  // Bot ditambahkan ke grup
  if ((oldStatus === 'left' || oldStatus === 'kicked') && 
      (newStatus === 'member' || newStatus === 'administrator')) {
    
    // Cek apakah yang menambahkan adalah admin sistem
    const isSystemAdmin = await VerificationManager.isSystemAdmin(addedBy.id);
    
    if (!isSystemAdmin) {
      await ctx.telegram.sendMessage(
        ctx.chat.id, 
        '⚠️ Bot hanya dapat ditambahkan oleh admin sistem yang terdaftar.\n' +
        'Bot akan keluar dari grup ini.'
      );
      await ctx.telegram.leaveChat(ctx.chat.id);
      return;
    }
    
    // Tambahkan grup ke admin yang menambahkan bot
    const groupAdded = await VerificationManager.addGroupToAdmin(addedBy.id, groupId, groupTitle);
    
    if (groupAdded) {
      await ctx.reply(
        `✅ Bot berhasil ditambahkan ke grup ${groupTitle}!\n\n` +
        '🔒 Hanya admin yang terdaftar yang dapat menggunakan bot ini.\n' +
        '📝 Grup ini telah didaftarkan untuk admin yang menambahkan bot.\n\n' +
        'Ketik /start untuk memulai atau /menu untuk melihat fitur bot.'
      );
    } else {
      await ctx.reply('❌ Gagal mendaftarkan grup. Silakan coba lagi.');
    }
  }
  
  // Bot dikeluarkan dari grup
  if (newStatus === 'left' || newStatus === 'kicked') {
    console.log(`Bot dikeluarkan dari grup: ${groupTitle} (${groupId})`);
    
    // Hapus grup dari admin (opsional)
    if (addedBy?.id) {
      await VerificationManager.removeGroupFromAdmin(addedBy.id);
      console.log(`Grup ${groupTitle} dihapus dari admin ${addedBy.id}`);
    }
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