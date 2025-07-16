import { Telegraf, Context } from 'telegraf';
import { supabase } from '../database';
import { VerificationManager } from '../utils/verification';

// Set untuk mencegah duplikasi pesan
const processedMessages = new Set<string>();

export function handleStart(bot: Telegraf) {
  // Set menu commands untuk bot
  bot.telegram.setMyCommands([
    { command: 'start', description: 'Mulai verifikasi dan sambungkan grup' },
    { command: 'menu', description: 'Tampilkan menu utama' },
    { command: 'status', description: 'Lihat status notifikasi' }
  ]);

  bot.command('start', async (ctx: Context) => {
    const userId = ctx.from?.id;
    const chatType = ctx.chat?.type;
    
    if (!userId) return ctx.reply('❌ Tidak dapat mengidentifikasi user.');

    // Jika di grup, cek apakah user adalah admin yang diizinkan dan sambungkan grup
    if (chatType === 'group' || chatType === 'supergroup') {
      const hasAccess = await VerificationManager.validateAccess(ctx);
      
      if (!hasAccess) {
        const isAdmin = await VerificationManager.isSystemAdmin(userId);
        if (!isAdmin) {
          await ctx.reply('❌ Anda tidak memiliki akses untuk menggunakan bot di grup ini.');
          return;
        }

        // Jika admin sistem tapi grup belum terhubung, sambungkan otomatis
        const groupId = ctx.chat?.id;
        const groupTitle = ctx.chat?.title || 'Grup Tanpa Nama';
        
        if (!groupId) {
          await ctx.reply('❌ Tidak dapat mengidentifikasi grup.');
          return;
        }
        
        // Tambahkan grup ke admin yang menambahkan bot
        const groupAdded = await VerificationManager.addGroupToAdmin(userId, groupId, groupTitle);
        
        if (groupAdded) {
          await ctx.reply(
            `✅ Bot berhasil disambungkan ke grup ${groupTitle}!\n\n` +
            '🔒 Hanya admin yang terdaftar yang dapat menggunakan bot ini.\n' +
            '📝 Grup ini telah didaftarkan untuk admin yang menjalankan perintah.\n\n' +
            'Gunakan /menu untuk melihat fitur yang tersedia.'
          );
          return;
        } else {
          await ctx.reply('❌ Gagal mendaftarkan grup. Silakan coba lagi.');
          return;
        }
      }

      // Jika di grup dan sudah tervalidasi, tampilkan pesan selamat datang
      await ctx.reply(
        '✅ Selamat datang di bot notifikasi!\n\n' +
        '🤖 Bot siap digunakan di grup ini.\n' +
        '📝 Gunakan /menu untuk melihat fitur yang tersedia.'
      );
      return;
    }

    // Jika di private chat, lakukan verifikasi normal
    VerificationManager.initializeVerification(userId);
    await ctx.reply(
      '🤖 Selamat datang di Bot Notifikasi!\n\n' +
      '🔐 Untuk menggunakan bot ini, Anda perlu verifikasi terlebih dahulu.\n\n' +
      '👤 Silakan masukkan username Anda:'
    );
  });
  
  // Command untuk menampilkan menu
  bot.command('menu', async (ctx: Context) => {
    const userId = ctx.from?.id;
    const chatType = ctx.chat?.type;
    
    if (!userId) return ctx.reply('❌ Tidak dapat mengidentifikasi user.');

    // Jika di grup, validasi akses terlebih dahulu
    if (chatType === 'group' || chatType === 'supergroup') {
      const hasAccess = await VerificationManager.validateAccess(ctx);
      
      if (!hasAccess) {
        await ctx.reply('❌ Anda tidak memiliki akses untuk menggunakan bot di grup ini.');
        return;
      }
    }

    // Cek apakah user sudah terverifikasi di tabel user_roles
    const { data: userData } = await supabase
      .from('user_roles')
      .select('user_name, role_id, telegram_id, grup_id')
      .eq('telegram_id', userId)
      .single();

    if (!userData) {
      const message = chatType === 'private' 
        ? '❌ Anda belum terverifikasi. Gunakan /start untuk verifikasi terlebih dahulu.'
        : '❌ Anda belum terverifikasi. Silakan chat bot secara private untuk verifikasi.';
      return ctx.reply(message);
    }

    // Translate role_id ke nama role
    let roleName = 'Unknown';
    if (userData.role_id === 1) {
      roleName = 'admin';
    } else if (userData.role_id === 2) {
      roleName = 'waspang';
    }

    const groupInfo = userData.grup_id 
      ? `\n• Grup Terdaftar: ${userData.grup_id}` 
      : '\n• Grup Terdaftar: Tidak ada';

    await ctx.reply(`📋 Menu Utama

👤 Info Anda:
• Nama Telegram: ${ctx.from?.username || ctx.from?.first_name || 'Tidak diketahui'}
• Role: ${roleName}${groupInfo}

🔧 Perintah yang tersedia:
/start - Mulai verifikasi ulang
/menu - Tampilkan menu ini
/status - Lihat status notifikasi`);
  });
  
  // Command untuk index pesan
  bot.command('indexmsg', async (ctx: Context) => {
    const userId = ctx.from?.id;
    const chatType = ctx.chat?.type;
    
    if (!userId) return ctx.reply('❌ Tidak dapat mengidentifikasi user.');

    // Validasi akses
    if (chatType === 'group' || chatType === 'supergroup') {
      const hasAccess = await VerificationManager.validateAccess(ctx);
      if (!hasAccess) {
        await ctx.reply('❌ Anda tidak memiliki akses untuk menggunakan bot di grup ini.');
        return;
      }
    } else if (chatType === 'private') {
      const isAdmin = await VerificationManager.isSystemAdmin(userId);
      const isWaspang = await VerificationManager.isWaspang(userId);
      
      // Izinkan waspang menggunakan fitur indexmsg di chat pribadi
      if (!isAdmin && !isWaspang) {
        await ctx.reply('❌ Anda tidak memiliki akses untuk menggunakan fitur ini.');
        return;
      }
    }

    await ctx.reply(
      '📝 Mode Index Pesan Aktif\n\n' +
      '✍️ Silakan kirim pesan yang ingin diindex untuk notifikasi otomatis.\n' +
      '💡 Pesan berikutnya yang Anda kirim akan disimpan sebagai template notifikasi.\n\n' +
      '❌ Ketik /cancel untuk membatalkan.'
    );

    // Set state untuk user ini sedang dalam mode index
    const state = VerificationManager.getVerificationState(userId) || { step: 'completed' };
    VerificationManager.updateVerificationState(userId, { 
      ...state, 
      step: 'indexing', 
      chatType: chatType,
      groupId: chatType === 'group' || chatType === 'supergroup' ? ctx.chat?.id : undefined
    });
  });

  // Command untuk cancel indexing
  bot.command('cancel', async (ctx: Context) => {
    const userId = ctx.from?.id;
    if (!userId) return;

    const state = VerificationManager.getVerificationState(userId);
    if (state?.step === 'indexing') {
      VerificationManager.updateVerificationState(userId, { ...state, step: 'completed' });
      await ctx.reply('❌ Mode index pesan dibatalkan.');
    }
  });

  // Command untuk melihat status
  bot.command('status', async (ctx: Context) => {
    const userId = ctx.from?.id;
    const chatType = ctx.chat?.type;
    
    if (!userId) return ctx.reply('❌ Tidak dapat mengidentifikasi user.');

    // Validasi akses
    if (chatType === 'group' || chatType === 'supergroup') {
      const hasAccess = await VerificationManager.validateAccess(ctx);
      if (!hasAccess) {
        await ctx.reply('❌ Anda tidak memiliki akses untuk menggunakan bot di grup ini.');
        return;
      }
    } else if (chatType === 'private') {
      const isAdmin = await VerificationManager.isSystemAdmin(userId);
      const isWaspang = await VerificationManager.isWaspang(userId);
      
      // Izinkan waspang untuk melihat status
      if (!isAdmin && !isWaspang) {
        await ctx.reply('❌ Anda tidak memiliki akses untuk menggunakan fitur ini.');
        return;
      }
    }

    // Ambil status notifikasi
    const { data: userData } = await supabase
      .from('user_roles')
      .select('user_name, bot_message, is_send, sent_at, grup_id')
      .eq('telegram_id', userId)
      .single();

    if (!userData) {
      return ctx.reply('❌ Data user tidak ditemukan.');
    }

    const hasMessage = userData.bot_message && userData.bot_message.trim() !== '';
    const targetChat = chatType === 'group' || chatType === 'supergroup' ? 'grup' : 'personal';
    
    let statusText = `📊 Status Notifikasi - ${userData.user_name}\n\n`;
    
    if (hasMessage) {
      statusText += `📝 Pesan tersimpan: ✅\n`;
      statusText += `📤 Status kirim: ${userData.is_send ? '✅ Terkirim' : '⏳ Pending'}\n`;
      if (userData.sent_at) {
        statusText += `🕐 Terkirim pada: ${new Date(userData.sent_at).toLocaleString('id-ID')}\n`;
      }
      statusText += `🎯 Target: ${targetChat}\n\n`;
      statusText += `💬 Preview pesan:\n"${userData.bot_message.substring(0, 100)}${userData.bot_message.length > 100 ? '...' : ''}"`;
    } else {
      statusText += `📝 Pesan tersimpan: ❌\n`;
      statusText += `💡 Gunakan /indexmsg untuk menyimpan pesan notifikasi.`;
    }

    await ctx.reply(statusText);
  });
  
  bot.on('text', async (ctx) => {
    const userId = ctx.from?.id;
    const messageId = ctx.message?.message_id;
    const telegramUsername = ctx.from?.username || ctx.from?.first_name || `tg_${userId}`;
    const chatType = ctx.chat?.type;
    
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

    // Cek state user
    const state = VerificationManager.getVerificationState(userId);
    if (!state) return;

    const text = ctx.message.text;

    // Handle indexing pesan
    if (state.step === 'indexing') {
      try {
        // Validasi akses untuk indexing
        let hasAccess = false;
        if (chatType === 'group' || chatType === 'supergroup') {
          hasAccess = await VerificationManager.validateAccess(ctx);
        } else if (chatType === 'private') {
          const isAdmin = await VerificationManager.isSystemAdmin(userId);
          const isWaspang = await VerificationManager.isWaspang(userId);
          hasAccess = isAdmin || isWaspang;
        }

        if (!hasAccess) {
          await ctx.reply('❌ Anda tidak memiliki akses untuk menggunakan fitur ini.');
          VerificationManager.updateVerificationState(userId, { ...state, step: 'completed' });
          return;
        }

        // Tentukan grup_id berdasarkan context saat indexing dilakukan
        let grupId: number | null = null;
        if (chatType === 'group' || chatType === 'supergroup') {
          grupId = ctx.chat?.id || null;
        }

        // Update bot_message dan reset is_send
        const { error: updateError } = await supabase
          .from('user_roles')
          .update({ 
            bot_message: text,
            is_send: false,
            sent_at: null,
            grup_id: grupId // Set grup_id jika di grup
          })
          .eq('telegram_id', userId);  // Hapus filter role_id agar waspang bisa menggunakan fitur ini

        if (updateError) {
          console.error('Error updating bot_message:', updateError);
          await ctx.reply('❌ Gagal menyimpan pesan. Silakan coba lagi.');
          return;
        }

        // Update state kembali ke completed
        VerificationManager.updateVerificationState(userId, { ...state, step: 'completed' });

        const targetInfo = grupId ? `grup ini` : `chat personal`;
        
        await ctx.reply(
          `✅ Pesan berhasil diindex!\n\n` +
          `📝 Target: ${targetInfo}\n` +
          `📤 Status: Menunggu pengiriman otomatis\n\n` +
          `💬 Preview:\n"${text.substring(0, 100)}${text.length > 100 ? '...' : ''}"\n\n` +
          `🔔 Pesan akan dikirim secara otomatis oleh sistem.`
        );

        console.log(`✅ Message indexed by ${telegramUsername} (${userId}) for ${targetInfo}: "${text.substring(0, 50)}..."`);

      } catch (error) {
        console.error('Error during message indexing:', error);
        await ctx.reply('❌ Terjadi kesalahan saat menyimpan pesan.');
        VerificationManager.updateVerificationState(userId, { ...state, step: 'completed' });
      }
      return;
    }

    // Handle verifikasi (hanya di private chat)
    if (chatType !== 'private') return;
    if (state.step === 'completed') return;

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

        // CATATAN: Kode ini melarang waspang menggunakan bot
        // Hapus atau ubah blok ini untuk mengizinkan waspang
        // if (roleInput === 'waspang') {
        //   VerificationManager.updateVerificationState(userId, { step: 'completed' });
        //   return ctx.reply('❌ Tidak diizinkan memakai bot');
        // }

        const isValid = await VerificationManager.verifyCredentials(userId, state.username!, roleInput);
        if (!isValid) {
          console.log(`❌ Failed verification for user ${userId}: ${state.username} / ${roleInput}`);
          return ctx.reply(`❌ Username atau role salah.\nGunakan /start untuk mencoba lagi.`);
        }

        console.log(`✅ Successful verification for user ${userId}: ${state.username} / ${roleInput}`);
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

          // Tambahkan log untuk membantu debugging
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
