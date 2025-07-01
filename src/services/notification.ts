import { supabase } from '../database';
import { Telegram } from 'telegraf';

export class NotificationService {
  static async processAndSendNotifications(telegram: Telegram): Promise<void> {
    try {
      // Ambil semua data dari user_roles yang memiliki bot_message dan belum terkirim
      const { data: pendingMessages, error: fetchError } = await supabase
        .from('user_roles')
        .select('id, user_name, telegram_id, bot_message, is_send')
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
      for (const messageData of pendingMessages) {
        const { id, user_name, telegram_id, bot_message } = messageData;

        if (!telegram_id) {
          console.log(`⚠️ No telegram_id for role: ${user_name}`);
          continue;
        }

        try {
          // Kirim pesan ke telegram_id
          await telegram.sendMessage(telegram_id, `📋 Laporan untuk ${user_name}

${bot_message}

—
Dikirim secara otomatis oleh sistem`);

          // Update status menjadi terkirim
          const currentTime = new Date().toISOString();
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
            console.log(`✅ Message sent to ${user_name} (${telegram_id}) at ${currentTime}`);
          }

        } catch (sendError) {
          console.error(`❌ Failed to send message to ${user_name} (${telegram_id}):`, sendError);
        }
      }

    } catch (error) {
      console.error('Notification processing error:', error);
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
    } catch (error) {
      console.error('Error in checkPendingMessages:', error);
      return 0;
    }
  }
}
