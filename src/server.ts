import express, { Request, Response, Application, RequestHandler } from 'express';
import { supabase } from './database';

const app: Application = express();
const PORT = 3000;

// Middleware
app.use(express.json());

// Type untuk request body
interface NotificationRequest {
  message: string;
  userId: string | number;
}

// Perbaikan: Gunakan tipe yang lebih spesifik
const notificationHandler: RequestHandler<{}, any, NotificationRequest> = async (req, res): Promise<void> => {
  try {
    const { message, userId } = req.body;

    // Validasi input
    if (!message || !userId) {
      res.status(400).json({ 
        error: 'Message and userId are required',
        details: {
          received: { message, userId }
        }
      }).end();
      return;
    }

    // Simpan ke database
    const { data, error } = await supabase
      .from('notifications')
      .insert([{ 
        user_id: userId, 
        message,
        created_at: new Date().toISOString() 
      }])
      .select();

    if (error) {
      throw new Error(`Supabase error: ${error.message}`);
    }

    res.status(201).json({ 
      success: true, 
      data,
      meta: {
        timestamp: new Date().toISOString()
      }
    }).end();
    return;

  } catch (error) {
    console.error('Error in notificationHandler:', error);
    res.status(500).json({ 
      error: 'Internal server error',
      ...(error instanceof Error && { details: error.message })
    }).end();
    return;
  }
};

// Endpoint untuk notifikasi
app.post('/api/telegram-notify', notificationHandler);

// Endpoint untuk health check
app.get('/health', (req: Request, res: Response) => {
  res.status(200).json({ 
    status: 'OK',
    timestamp: new Date().toISOString() 
  }).end();
});

// Error handling middleware
app.use((err: Error, req: Request, res: Response, next: Function) => {
  console.error('Global error handler:', err);
  res.status(500).json({
    error: 'Something went wrong',
    details: process.env.NODE_ENV === 'development' ? err.message : undefined
  }).end();
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
  console.log(`Notification endpoint: POST http://localhost:${PORT}/api/telegram-notify`);
});