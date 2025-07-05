-- Migration: Add bot_message and is_sent columns to user_roles table
-- Created: 2025-07-01
-- Purpose: Support Excel export bot message functionality

-- Add bot_message column to store Excel export data
ALTER TABLE public.user_roles 
ADD COLUMN IF NOT EXISTS bot_message TEXT DEFAULT '';

-- Add is_send column to track message status
ALTER TABLE public.user_roles 
ADD COLUMN IF NOT EXISTS is_send BOOLEAN DEFAULT false;

-- Add sent_at column to track when message was sent
ALTER TABLE public.user_roles 
ADD COLUMN IF NOT EXISTS sent_at TIMESTAMPTZ NULL;

-- Add grup_id column for grouping users (if needed for bot messaging)
ALTER TABLE public.user_roles 
ADD COLUMN IF NOT EXISTS grup_id BIGINT NULL;

-- Add telegram_id column for Telegram integration
ALTER TABLE public.user_roles 
ADD COLUMN IF NOT EXISTS telegram_id BIGINT NULL;

-- Add index for better performance when querying unsent messages
CREATE INDEX IF NOT EXISTS idx_user_roles_is_send ON public.user_roles(is_send);
CREATE INDEX IF NOT EXISTS idx_user_roles_sent_at ON public.user_roles(sent_at);
CREATE INDEX IF NOT EXISTS idx_user_roles_grup_id ON public.user_roles(grup_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_telegram_id ON public.user_roles(telegram_id);

-- Add index for bot_message column (for searching)
CREATE INDEX IF NOT EXISTS idx_user_roles_bot_message ON public.user_roles USING gin(to_tsvector('english', bot_message));

-- Add comment to document the new columns
COMMENT ON COLUMN public.user_roles.bot_message IS 'Stores Excel export content from column I for bot messaging purposes';
COMMENT ON COLUMN public.user_roles.is_send IS 'Boolean flag to track if the bot message has been sent';
COMMENT ON COLUMN public.user_roles.sent_at IS 'Timestamp when the bot message was sent';
COMMENT ON COLUMN public.user_roles.grup_id IS 'Group ID for organizing users in bot messaging';
COMMENT ON COLUMN public.user_roles.telegram_id IS 'Telegram ID for user, used in bot messaging';

-- Create function to clear bot messages for all users
CREATE OR REPLACE FUNCTION public.clear_all_bot_messages()
RETURNS void
LANGUAGE SQL
SECURITY DEFINER
SET search_path = ''
AS $$
  UPDATE public.user_roles 
  SET bot_message = '', is_send = false, sent_at = NULL;
$$;

-- Create function to get unsent bot messages
CREATE OR REPLACE FUNCTION public.get_unsent_bot_messages()
RETURNS TABLE(
  user_id UUID,
  user_name TEXT,
  role_name TEXT,
  bot_message TEXT
)
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT 
    ur.user_id,
    ur.user_name,
    r.name as role_name,
    ur.bot_message
  FROM public.user_roles ur
  JOIN public.roles r ON ur.role_id = r.id
  WHERE ur.bot_message IS NOT NULL 
    AND ur.bot_message != '' 
    AND ur.is_send = false;
$$;

-- Create function to mark bot message as sent
CREATE OR REPLACE FUNCTION public.mark_bot_message_sent(target_user_id UUID)
RETURNS void
LANGUAGE SQL
SECURITY DEFINER
SET search_path = ''
AS $$
  UPDATE public.user_roles 
  SET is_send = true, sent_at = NOW()
  WHERE user_id = target_user_id;
$$;

-- Create function to mark bot message as sent for multiple users
CREATE OR REPLACE FUNCTION public.mark_bot_messages_sent_bulk(target_user_ids UUID[])
RETURNS void
LANGUAGE SQL
SECURITY DEFINER
SET search_path = ''
AS $$
  UPDATE public.user_roles 
  SET is_send = true, sent_at = NOW()
  WHERE user_id = ANY(target_user_ids);
$$;

-- Update RLS policies to allow access to bot_message columns
-- This is already covered by existing user_roles policies, but we add a comment for clarity

-- Log the completion
DO $$
BEGIN
  RAISE NOTICE 'Bot message columns have been added to user_roles table successfully';
  RAISE NOTICE 'New columns: bot_message (TEXT), is_send (BOOLEAN), sent_at (TIMESTAMPTZ), grup_id (BIGINT), telegram_id (BIGINT)';
  RAISE NOTICE 'Indexes created for performance optimization';
  RAISE NOTICE 'Helper functions created for bot message management';
END $$;
