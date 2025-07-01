import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';

dotenv.config();

// Validasi environment variables
if (!process.env.SUPABASE_URL) {
  throw new Error('SUPABASE_URL is required in .env file');
}

if (!process.env.SUPABASE_SERVICE_KEY) {
  throw new Error('SUPABASE_SERVICE_KEY is required in .env file');
}

export const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY,
  {
    auth: {
      persistSession: false,
      autoRefreshToken: false
    }
  }
);