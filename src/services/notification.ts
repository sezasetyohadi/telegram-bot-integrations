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
  // Set untuk mencegah duplikasi pengiriman
  private static processedMessages = new Set<string>();

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

        // Buat key unik untuk mencegah duplikasi
        const messageKey = `${id}_${telegram_id}_${grup_id || 'private'}`;
        
        if (this.processedMessages.has(messageKey)) {
          console.log(`⚠️ Skipping duplicate message for ${user_name} (${messageKey})`);
          continue;
        }

        if (!telegram_id) {
          console.log(`⚠️ No telegram_id for role: ${user_name}`);
          continue;
        }

        try {
          // Tentukan target chat (grup atau personal)
          const chatId = grup_id || telegram_id;
          const chatType = grup_id ? 'grup' : 'personal';
          
          // Format pesan
          const message = `📋 Laporan

${bot_message}

—
Dikirim secara otomatis ke ${chatType}`;

          // Kirim pesan
          await telegram.sendMessage(chatId, message);

          // Tandai sebagai sudah diproses
          this.processedMessages.add(messageKey);

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
            console.log(`✅ Message sent to ${user_name} (${chatType}: ${chatId}) at ${currentTime}`);
          }

        } catch (sendError) {
          console.error(`❌ Failed to send message to ${user_name} (${telegram_id}):`, sendError);
        }
      }

      // Bersihkan set jika terlalu besar
      if (this.processedMessages.size > 1000) {
        const entries = Array.from(this.processedMessages);
        this.processedMessages.clear();
        entries.slice(-500).forEach(entry => this.processedMessages.add(entry));
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
