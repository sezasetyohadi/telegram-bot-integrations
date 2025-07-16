import { Telegraf, Context } from 'telegraf';
import { supabase } from '../database';

/**
 * Class untuk mengelola interaksi bot dengan grup
 */
export class GroupManager {
  /**
   * Menangani ketika bot ditambahkan ke grup baru
   */
  static async handleBotAddedToGroup(ctx: Context): Promise<void> {
    if (!ctx.chat || (ctx.chat.type !== 'group' && ctx.chat.type !== 'supergroup')) {
      return;
    }

    const groupId = ctx.chat.id;
    const groupTitle = ctx.chat.title || 'Grup Tanpa Nama';
    
    console.log(`✅ Bot ditambahkan ke grup baru: ${groupTitle} (${groupId})`);
    
    // Log info grup
    await ctx.reply(`✅ Bot telah ditambahkan ke grup ${groupTitle}!
    
🔑 Group ID: ${groupId}
📝 Gunakan /start untuk menghubungkan akun Anda dengan grup ini.
❓ Gunakan /menu untuk melihat fitur yang tersedia di grup ini.`);
  }

  /**
   * Menangani ketika bot dihapus dari grup
   */
  static async handleBotRemovedFromGroup(ctx: Context): Promise<void> {
    if (!ctx.chat || (ctx.chat.type !== 'group' && ctx.chat.type !== 'supergroup')) {
      return;
    }

    const groupId = ctx.chat.id;
    const groupTitle = ctx.chat.title || 'Grup Tanpa Nama';
    
    console.log(`❌ Bot dihapus dari grup: ${groupTitle} (${groupId})`);
    
    try {
      // Hapus grup_id dari semua user yang terhubung ke grup ini
      const { error } = await supabase
        .from('user_roles')
        .update({ grup_id: null })
        .eq('grup_id', groupId);
        
      if (error) {
        console.error(`Error menghapus grup_id dari user:`, error);
      } else {
        console.log(`✅ Berhasil menghapus referensi ke grup ${groupId} dari database`);
      }
    } catch (error) {
      console.error('Error saat menangani bot dihapus dari grup:', error);
    }
  }

  /**
   * Memeriksa apakah bot masih ada di grup
   */
  static async isBotInGroup(bot: Telegraf, groupId: number): Promise<boolean> {
    try {
      // Coba dapatkan info grup - akan error jika bot tidak ada di grup
      await bot.telegram.getChat(groupId);
      return true;
    } catch (error) {
      console.log(`Bot tidak ada di grup ${groupId}, menghapus referensi grup...`);
      
      // Hapus grup_id dari user yang terhubung
      try {
        const { error: updateError } = await supabase
          .from('user_roles')
          .update({ grup_id: null })
          .eq('grup_id', groupId);
          
        if (updateError) {
          console.error(`Error menghapus grup_id:`, updateError);
        }
      } catch (dbError) {
        console.error('Database error:', dbError);
      }
      
      return false;
    }
  }

  /**
   * Verifikasi semua grup untuk memastikan bot masih ada di grup tersebut
   */
  static async verifyAllGroups(bot: Telegraf): Promise<void> {
    try {
      // Ambil semua grup_id unik dari database
      const { data, error } = await supabase
        .from('user_roles')
        .select('grup_id')
        .not('grup_id', 'is', null);
        
      if (error) {
        console.error('Error mengambil daftar grup:', error);
        return;
      }
      
      // Set untuk menyimpan grup_id unik
      const uniqueGroupIds = new Set<number>();
      data.forEach(item => {
        if (item.grup_id) uniqueGroupIds.add(item.grup_id);
      });
      
      console.log(`🔍 Memverifikasi ${uniqueGroupIds.size} grup...`);
      
      // Verifikasi setiap grup
      for (const groupId of uniqueGroupIds) {
        const isActive = await this.isBotInGroup(bot, groupId);
        console.log(`Grup ${groupId}: ${isActive ? '✅ Aktif' : '❌ Tidak aktif'}`);
      }
      
      console.log('✅ Verifikasi grup selesai');
    } catch (error) {
      console.error('Error saat verifikasi grup:', error);
    }
  }
}
