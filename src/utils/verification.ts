import { supabase } from '../database';
import { Context } from 'telegraf';

interface VerificationState {
  step: 'username' | 'role' | 'completed' | 'indexing';
  username?: string;
  role?: string;
  chatType?: string;
  groupId?: number;
}

const userVerification = new Map<number, VerificationState>();

export class VerificationManager {
  static initializeVerification(userId: number) {
    userVerification.set(userId, {
      step: 'username'
    });
  }

  static async verifyCredentials(userId: number, username: string, role: string): Promise<boolean> {
    try {
      // Mapping role input ke role_id
      let roleId: number;
      if (role === 'admin') {
        roleId = 1; // admin = role_id 1
      } else if (role === 'waspang') {
        roleId = 2; // waspang = role_id 2
      } else {
        console.log('Invalid role input');
        return false;
      }

      // Cek apakah username DAN role_id cocok di tabel user_roles
      const { data, error } = await supabase
        .from('user_roles')
        .select('user_name, role_id')
        .eq('user_name', username)
        .eq('role_id', roleId)
        .single();

      if (error) {
        console.log('Username dan role tidak cocok di user_roles table:', error);
        return false;
      }

      // Jika data ditemukan dan cocok, return true
      return data !== null;
    } catch (err) {
      console.error('Verification error:', err);
      return false;
    }
  }

  static getVerificationState(userId: number): VerificationState | undefined {
    return userVerification.get(userId);
  }

  static updateVerificationState(userId: number, updates: Partial<VerificationState>) {
    const currentState = userVerification.get(userId);
    if (currentState) {
      userVerification.set(userId, { ...currentState, ...updates });
    }
  }

  // Validasi untuk grup - cek apakah user adalah admin di grup yang terdaftar
  static async isUserAuthorizedInGroup(ctx: Context): Promise<boolean> {
    try {
      if (!ctx.chat || ctx.chat.type === 'private') {
        return false;
      }

      const userId = ctx.from?.id;
      const groupId = ctx.chat.id;
      
      if (!userId) return false;

      // Dapatkan administrator grup
      const admins = await ctx.telegram.getChatAdministrators(groupId);
      
      // Cek apakah user adalah admin di grup Telegram
      const isGroupAdmin = admins.some(admin => admin.user.id === userId);
      
      if (!isGroupAdmin) {
        return false;
      }

      // Cek apakah user terdaftar sebagai admin di sistem DAN grup ini terdaftar
      // Untuk grup, hanya admin yang bisa mengakses
      return await this.isAuthorizedAdminInGroup(userId, groupId);
    } catch (error) {
      console.error('Error checking group authorization:', error);
      return false;
    }
  }

  // Cek apakah user adalah admin sistem yang diizinkan di grup ini
  static async isAuthorizedAdminInGroup(userId: number, groupId: number): Promise<boolean> {
    try {
      // Untuk grup, hanya admin yang diizinkan
      const { data, error } = await supabase
        .from('user_roles')
        .select('user_name, role_id, grup_id, telegram_id')
        .eq('telegram_id', userId)
        .eq('role_id', 1) // hanya admin
        .eq('grup_id', groupId)
        .single();

      if (error) {
        console.log('User tidak diizinkan di grup ini:', error);
        return false;
      }

      return data !== null;
    } catch (error) {
      console.error('Error checking admin authorization in group:', error);
      return false;
    }
  }

  // Cek apakah user adalah admin sistem (untuk private chat)
  static async isSystemAdmin(userId: number): Promise<boolean> {
    try {
      const { data, error } = await supabase
        .from('user_roles')
        .select('user_name, role_id, telegram_id')
        .eq('telegram_id', userId)
        .eq('role_id', 1) // hanya admin
        .single();

      if (error) return false;
      return data !== null;
    } catch (error) {
      console.error('Error checking system admin status:', error);
      return false;
    }
  }

  // Validasi akses berdasarkan tipe chat
  static async validateAccess(ctx: Context): Promise<boolean> {
    // Jika di private chat, cek apakah user adalah admin sistem atau waspang
    if (ctx.chat?.type === 'private') {
      const userId = ctx.from?.id;
      if (!userId) return false;
      // Cek admin atau waspang
      return await this.isSystemAdmin(userId) || await this.isWaspang(userId);
    }

    // Jika di grup, cek apakah user adalah admin grup yang terdaftar
    return await this.isUserAuthorizedInGroup(ctx);
  }
  
  // Cek apakah user adalah waspang
  static async isWaspang(userId: number): Promise<boolean> {
    try {
      const { data, error } = await supabase
        .from('user_roles')
        .select('user_name, role_id, telegram_id')
        .eq('telegram_id', userId)
        .eq('role_id', 2) // waspang = role_id 2
        .single();

      if (error) return false;
      return data !== null;
    } catch (error) {
      console.error('Error checking waspang status:', error);
      return false;
    }
  }

  // Tambahkan grup ke user admin
  static async addGroupToAdmin(userId: number, groupId: number, groupTitle: string): Promise<boolean> {
    try {
      // Cek apakah user adalah admin sistem - untuk grup hanya admin yang diizinkan
      const isAdmin = await this.isSystemAdmin(userId);
      if (!isAdmin) {
        return false;
      }

      // Update grup_id untuk admin ini
      const { error } = await supabase
        .from('user_roles')
        .update({ grup_id: groupId })
        .eq('telegram_id', userId)
        .eq('role_id', 1);

      if (error) {
        console.error('Error adding group to admin:', error);
        return false;
      }

      console.log(`✅ Grup ${groupTitle} (${groupId}) ditambahkan untuk admin ${userId}`);
      return true;
    } catch (error) {
      console.error('Error in addGroupToAdmin:', error);
      return false;
    }
  }

  // Hapus grup dari admin
  static async removeGroupFromAdmin(userId: number): Promise<boolean> {
    try {
      // Cek apakah user adalah admin (hanya admin yang bisa mengelola grup)
      const isAdmin = await this.isSystemAdmin(userId);
      if (!isAdmin) {
        return false;
      }
      
      const { error } = await supabase
        .from('user_roles')
        .update({ grup_id: null })
        .eq('telegram_id', userId)
        .eq('role_id', 1);

      if (error) {
        console.error('Error removing group from admin:', error);
        return false;
      }

      return true;
    } catch (error) {
      console.error('Error in removeGroupFromAdmin:', error);
      return false;
    }
  }
}
