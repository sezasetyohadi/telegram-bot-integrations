import { Telegraf, Context } from 'telegraf';
import { supabase } from '../database';
import { VerificationManager } from '../utils/verification';

// Set untuk mencegah duplikasi pesan
const processedMessages = new Set<string>();

export function handleStart(bot: Telegraf) {
  // Set menu commands untuk bot
  bot.telegram.setMyCommands([
    { command: 'start', description: 'Mulai verifikasi' },
    { command: 'menu', description: 'Tampilkan menu utama' }
  ]);

  bot.command('start', async (ctx: Context) => {
    const userId = ctx.from?.id;
    if (!userId) return ctx.reply('❌ Tidak dapat mengidentifikasi user.');
    VerificationManager.initializeVerification(userId);
    await ctx.reply('Silakan masukkan username Anda:');
  });
  
  // Command untuk menampilkan menu
  bot.command('menu', async (ctx: Context) => {
    const userId = ctx.from?.id;
    if (!userId) return ctx.reply('❌ Tidak dapat mengidentifikasi user.');

    // Cek apakah user sudah terverifikasi di tabel user_roles
    const { data: userData } = await supabase
      .from('user_roles')
      .select('user_name, role_id, telegram_id')
      .eq('telegram_id', userId)
      .single();

    if (!userData) {
      return ctx.reply('❌ Anda belum terverifikasi. Gunakan /start untuk verifikasi terlebih dahulu.');
    }

    // Translate role_id ke nama role
    let roleName = 'Unknown';
    if (userData.role_id === 1) {
      roleName = 'admin';
    } else if (userData.role_id === 2) {
      roleName = 'waspang';
    }

    await ctx.reply(`📋 Menu Utama

👤 Info Anda:
• Nama Telegram: ${ctx.from?.username || ctx.from?.first_name || 'Tidak diketahui'}
• Role: ${roleName}

🔧 Perintah yang tersedia:
/start - Mulai verifikasi ulang
/menu - Tampilkan menu ini`);
  });
  
  bot.on('text', async (ctx) => {
    const userId = ctx.from?.id;
    const messageId = ctx.message?.message_id;
    const telegramUsername = ctx.from?.username || ctx.from?.first_name || `tg_${userId}`;
    
    if (!userId || !messageId || ctx.message.text.startsWith('/')) return;

    // Cegah duplikasi pesan
    const messageKey = `${userId}_${messageId}`;
    if (processedMessages.has(messageKey)) {
      console.log(`⚠️ Duplicate message detected for user ${userId}, message ${messageId}`);
      return;
    }
    
    // Tandai pesan sudah diproses
    processedMessages.add(messageKey);
    
    // Bersihkan set jika terlalu besar (maksimal 1000 entries)
    if (processedMessages.size > 1000) {
      const entries = Array.from(processedMessages);
      processedMessages.clear();
      // Simpan hanya 500 entries terakhir
      entries.slice(-500).forEach(entry => processedMessages.add(entry));
    }

    // Only handle verification if user is in verification state
    const state = VerificationManager.getVerificationState(userId);
    if (!state || state.step === 'completed') return;

    if (VerificationManager.isUserPenalized(userId)) {
      const remaining = Math.ceil(VerificationManager.getRemainingPenaltyTime(userId) / 1000);
      return ctx.reply(`⏳ Tunggu ${remaining} detik sebelum mencoba lagi.`);
    }

    const text = ctx.message.text;

    switch (state.step) {
      case 'username':
        console.log(`📝 User ${userId} entering username: ${text}`);
        VerificationManager.updateVerificationState(userId, { username: text, step: 'role' });
        await ctx.reply('Silakan masukkan role Anda (admin/waspang):');
        break;

      case 'role':
        console.log(`📝 User ${userId} entering role: ${text}`);
        // Validasi role input
        const roleInput = text.toLowerCase();
        if (roleInput !== 'waspang' && roleInput !== 'admin') {
          return ctx.reply('❌ Role harus "waspang" atau "admin". Silakan coba lagi:');
        }

        const isValid = await VerificationManager.verifyCredentials(userId, state.username!, roleInput);
        if (!isValid) {
          console.log(`❌ Failed verification for user ${userId}: ${state.username} / ${roleInput}`);
          const result = VerificationManager.handleFailedAttempt(userId);
          if (result.blocked) {
            return ctx.reply(`❌ Verifikasi gagal!\nTunggu ${Math.ceil(result.waitTime / 1000)} detik.\nGunakan /start untuk mencoba lagi.`);
          } else {
            const sisa = 3 - (VerificationManager.getVerificationState(userId)?.attempts || 0);
            return ctx.reply(`❌ Username atau role salah.\nSisa kesempatan: ${sisa}.\nGunakan /start untuk mencoba lagi.`);
          }
        }

        console.log(`✅ Successful verification for user ${userId}: ${state.username} / ${roleInput}`);
        VerificationManager.resetPenalties(userId);
        VerificationManager.updateVerificationState(userId, { role: roleInput, step: 'completed' });

        try {
          // Mapping role input ke role_id
          let roleId: number;
          if (roleInput === 'admin') {
            roleId = 1;
          } else if (roleInput === 'waspang') {
            roleId = 2;
          } else {
            throw new Error('Invalid role');
          }

          // Update telegram_id di tabel user_roles berdasarkan user_name DAN role_id
          const { error: roleUpdateError } = await supabase
            .from('user_roles')
            .update({ telegram_id: userId })
            .eq('user_name', state.username)
            .eq('role_id', roleId);

          if (roleUpdateError) {
            console.error('Error updating telegram_id in user_roles:', roleUpdateError);
            await ctx.reply('❌ Gagal menyimpan data verifikasi.');
            return;
          }

          console.log(`✅ User verified - Telegram ID: ${userId}, Username: ${telegramUsername}, Input Username: ${state.username}, Role: ${roleInput} (ID: ${roleId})`);

          await ctx.reply(`✅ Verifikasi berhasil!
👤 Nama Telegram: ${telegramUsername}
👤 Username: ${state.username}
🎭 Role: ${roleInput}

Selamat! Anda telah berhasil terverifikasi sebagai ${roleInput}.`);

        } catch (error) {
          console.error('Database error:', error);
          await ctx.reply('❌ Terjadi kesalahan database. Silakan coba lagi.');
        }
        break;
    }
  });
}
