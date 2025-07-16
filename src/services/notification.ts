import { supabase } from '../database';
import { Telegram } from 'telegraf';

interface PendingMessage {
  id: number;
  user_name: string;
  telegram_id: number;
  grup_id?: number;
  bot_message: string;
  is_send: boolean;
  sent_at?: string;
}

export class NotificationService {
  // Tidak lagi menggunakan Set untuk mencegah duplikasi
  // Mengandalkan flag is_send di database sebagai satu-satunya sumber kebenaran

  static async processAndSendNotifications(telegram: Telegram): Promise<void> {
    try {
      // Ambil semua data dari user_roles yang memiliki bot_message dan belum terkirim
      const { data: pendingMessages, error: fetchError } = await supabase
        .from('user_roles')
        .select('id, user_name, telegram_id, grup_id, bot_message, is_send, sent_at')
        .not('bot_message', 'is', null)
        .not('bot_message', 'eq', '')
        .eq('is_send', false);

      if (fetchError) {
        console.error('Error fetching pending messages:', fetchError);
        return;
      }

      if (!pendingMessages || pendingMessages.length === 0) {
        console.log('No pending messages to send');
        return;
      }

      console.log(`🔔 Processing ${pendingMessages.length} pending messages...`);

      // Proses setiap pesan yang pending
      for (const messageData of pendingMessages as PendingMessage[]) {
        const { id, user_name, telegram_id, grup_id, bot_message } = messageData;

        if (!telegram_id) {
          console.log(`⚠️ No telegram_id for role: ${user_name}`);
          continue;
        }

        // Hitung jumlah target pengiriman
        let successCount = 0;
        const targets = [];
        
        try {
          // Kirim ke chat pribadi jika ada telegram_id
          if (telegram_id) {
            try {
              // Format pesan untuk personal
              const personalMessage = `📋 Laporan

${bot_message}

—
Dikirim secara otomatis ke personal chat`;

              // Kirim pesan ke chat pribadi
              await telegram.sendMessage(telegram_id, personalMessage);
              console.log(`✅ Pesan terkirim ke ${user_name} (personal: ${telegram_id})`);
              successCount++;
              targets.push('personal');
            } catch (personalError: any) {
              console.error(`❌ Gagal mengirim ke chat pribadi ${user_name} (${telegram_id}):`, personalError.message || String(personalError));
            }
          }

          // Kirim ke grup jika ada grup_id
          if (grup_id) {
            // Verifikasi dulu apakah bot masih ada di grup
            try {
              // Coba dapatkan info chat - akan error jika bot tidak ada di grup
              await telegram.getChat(grup_id);
              
              // Format pesan untuk grup
              const groupMessage = `📋 Laporan

${bot_message}

—
Dikirim secara otomatis ke grup`;

              // Kirim pesan ke grup
              await telegram.sendMessage(grup_id, groupMessage);
              console.log(`✅ Pesan terkirim ke grup ${grup_id} untuk ${user_name}`);
              successCount++;
              targets.push('grup');
            } catch (groupError: any) {
              // Log error with just the message to keep logs cleaner
              console.error(`❌ Bot tidak lagi ada di grup ${grup_id}, menghapus referensi:`, groupError.message || String(groupError));
              
              // Hapus grup_id karena bot sudah tidak ada di grup
              try {
                const { error: updateGroupError } = await supabase
                  .from('user_roles')
                  .update({ grup_id: null })
                  .eq('id', id);
                  
                if (updateGroupError) {
                  console.error(`❌ Error menghapus grup_id untuk ${user_name}:`, updateGroupError.message || String(updateGroupError));
                } else {
                  console.log(`✅ Grup ${grup_id} dihapus dari referensi user ${user_name}`);
                }
              } catch (dbError: any) {
                console.error('Database error:', dbError.message || String(dbError));
              }
            }
          }

          // Update status menjadi terkirim jika berhasil kirim ke setidaknya satu target
          if (successCount > 0) {
            const currentTime = new Date().toISOString();
            const targetInfo = targets.join(' dan ');
            
            const { error: updateError } = await supabase
              .from('user_roles')
              .update({ 
                is_send: true,
                sent_at: currentTime
              })
              .eq('id', id);

            if (updateError) {
              console.error(`❌ Error updating send status for ${user_name}:`, updateError);
            } else {
              console.log(`✅ Status pesan untuk ${user_name} diperbarui (terkirim ke ${targetInfo}) pada ${currentTime}`);
            }
          } else {
            console.log(`⚠️ Tidak ada pesan yang terkirim untuk ${user_name}, status tetap pending`);
          }

        } catch (sendError: any) {
          console.error(`❌ Failed to send message to ${user_name} (${telegram_id}):`, sendError.message || String(sendError));
        }
      }

    } catch (error: any) {
      console.error('Notification processing error:', error.message || String(error));
    }
  }

  static async checkPendingMessages(): Promise<number> {
    try {
      const { data, error } = await supabase
        .from('user_roles')
        .select('id')
        .not('bot_message', 'is', null)
        .not('bot_message', 'eq', '')
        .eq('is_send', false);

      if (error) {
        console.error('Error checking pending messages:', error);
        return 0;
      }

      return data?.length || 0;
    } catch (error: any) {
      console.error('Error in checkPendingMessages:', error.message || String(error));
      return 0;
    }
  }
}
