import { supabase } from '../database';

interface VerificationState {
  step: 'username' | 'role' | 'completed';
  username?: string;
  role?: string;
  attempts: number;
  penalties: number;
  lastAttemptTime?: number;
  penaltyEndTime?: number;
}

const userVerification = new Map<number, VerificationState>();

export class VerificationManager {
  private static MAX_ATTEMPTS = 3;
  private static PENALTY_DURATION = 15000; // 15 detik dalam milidetik

  static isUserPenalized(userId: number): boolean {
    const state = userVerification.get(userId);
    if (!state?.penaltyEndTime) return false;
    return Date.now() < state.penaltyEndTime;
  }

  static getRemainingPenaltyTime(userId: number): number {
    const state = userVerification.get(userId);
    if (!state?.penaltyEndTime) return 0;
    return Math.max(0, state.penaltyEndTime - Date.now());
  }

  static initializeVerification(userId: number) {
    userVerification.set(userId, {
      step: 'username',
      attempts: 0,
      penalties: 0
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

  static handleFailedAttempt(userId: number): { blocked: boolean; waitTime: number } {
    const state = userVerification.get(userId);
    if (!state) return { blocked: false, waitTime: 0 };

    state.attempts++;

    if (state.attempts >= this.MAX_ATTEMPTS) {
      state.penalties++;
      state.attempts = 0;
      const penaltyMultiplier = state.penalties;
      const penaltyDuration = this.PENALTY_DURATION * penaltyMultiplier;
      state.penaltyEndTime = Date.now() + penaltyDuration;
      userVerification.set(userId, state);
      
      return { blocked: true, waitTime: penaltyDuration };
    }

    userVerification.set(userId, state);
    return { blocked: false, waitTime: 0 };
  }

  static resetPenalties(userId: number) {
    const state = userVerification.get(userId);
    if (state) {
      state.attempts = 0;
      state.penalties = 0;
      state.penaltyEndTime = undefined;
      userVerification.set(userId, state);
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
}
