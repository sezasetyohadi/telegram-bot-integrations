import { Telegraf, session } from 'telegraf';
import * as dotenv from 'dotenv';
import cron from 'node-cron';
import { handleStart } from './commands/start';
import { NotificationService } from './services/notification';
import { VerificationManager } from './utils/verification';
import { GroupManager } from './utils/group-manager';
import { setupGlobalErrorHandlers } from './utils/error-handler';

// Set up global error handlers to prevent crashes
setupGlobalErrorHandlers();

dotenv.config();

// Token bot HARUS dari environment variable
const bot = new Telegraf(process.env.TELEGRAM_BOT_TOKEN!);

// Export bot untuk digunakan di file lain
export { bot };

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
bot.catch((err: any, ctx) => {
  console.error(`Error for ${ctx.updateType}:`, err.message || String(err));
  
  // Only try to reply if we can - this might fail if the bot was kicked from a group
  try {
    ctx.reply('❌ Terjadi kesalahan. Silakan coba lagi.')
      .catch(replyError => {
        console.error('Failed to send error message:', replyError.message || String(replyError));
      });
  } catch (replyError: any) {
    console.error('Exception during error handling:', replyError.message || String(replyError));
  }
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
    // Verifikasi grup setiap 30 menit (ambil jam dan menit dari tanggal saat ini)
    const now = new Date();
    if (now.getMinutes() % 30 === 0 && now.getSeconds() < 10) {
      console.log('🔄 Menjalankan verifikasi grup...');
      await GroupManager.verifyAllGroups(bot);
    }
    
    // Proses notifikasi pending
    const pendingCount = await NotificationService.checkPendingMessages();
    if (pendingCount > 0) {
      console.log(`🔔 Found ${pendingCount} pending notifications, processing...`);
      await NotificationService.processAndSendNotifications(bot.telegram);
    }
  } catch (error: any) {
    console.error('Auto notification error:', error.message || String(error));
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
      
      // Panggil handler untuk bot ditambahkan ke grup
      await GroupManager.handleBotAddedToGroup(ctx);
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
    
    // Panggil handler untuk bot dihapus dari grup
    await GroupManager.handleBotRemovedFromGroup(ctx);
  }
});

// Bot tidak akan dijalankan dari sini lagi, tetapi dari index.ts
// if (!botStarted) {
//   bot.launch()
//     .then(() => {
//       botStarted = true;
//       console.log('🤖 Bot berjalan!');
//     })
//     .catch(err => console.error('💥 Gagal menjalankan bot:', err));
// } else {
//   console.log('⚠️ Bot sudah berjalan, skip launch');
// }

// Handle shutdown tidak lagi diperlukan di sini
// process.once('SIGINT', () => bot.stop('SIGINT'));
// process.once('SIGTERM', () => bot.stop('SIGTERM'));