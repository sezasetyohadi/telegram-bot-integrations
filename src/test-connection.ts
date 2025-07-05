// filepath: c:\Users\ADVAN\Documents\telegram-bot-integration\src\test-connection.ts
import { supabase } from './database';

async function testConnection() {
  try {
    const { data, error } = await supabase.from('roles').select('*').limit(1);
    
    if (error) {
      console.error('Error connecting to database:', error);
    } else {
      console.log('Connection successful!');
      console.log('Sample data:', data);
    }
  } catch (e) {
    console.error('Exception occurred:', e);
  }
}

testConnection();