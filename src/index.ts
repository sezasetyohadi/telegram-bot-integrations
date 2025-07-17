import { Telegraf } from 'telegraf';
import * as dotenv from 'dotenv';
import { bot } from './bot';

dotenv.config();

// Token bot dari environment variable
const botToken = process.env.TELEGRAM_BOT_TOKEN;
if (!botToken) {
  console.error('❌ TELEGRAM_BOT_TOKEN tidak ditemukan di environment variables');
  process.exit(1);
}

// Pastikan bot memiliki webhook kosong untuk long polling
bot.telegram.setWebhook('');

// Start bot
bot.launch()
  .then(() => {
    console.log('🤖 Bot telah berjalan!');
  })
  .catch((error: Error) => {
    console.error('❌ Error starting bot:', error);
  });

// Enable graceful stop
process.once('SIGINT', () => bot.stop('SIGINT'));
process.once('SIGTERM', () => bot.stop('SIGTERM'));
