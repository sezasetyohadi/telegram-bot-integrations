-- Migration: Create login_attempts table for server-side brute force protection
-- Created: 2025-07-02
-- Purpose: Track failed login attempts to prevent brute force attacks

-- Create login_attempts table
CREATE TABLE IF NOT EXISTS public.login_attempts (
  id SERIAL PRIMARY KEY,
  identifier TEXT NOT NULL, -- Can be email or IP address
  identifier_type VARCHAR(20) NOT NULL CHECK (identifier_type IN ('email', 'ip')),
  attempt_count INTEGER NOT NULL DEFAULT 1,
  first_attempt_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  last_attempt_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  blocked_until TIMESTAMP WITH TIME ZONE NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_login_attempts_identifier ON public.login_attempts(identifier);
CREATE INDEX IF NOT EXISTS idx_login_attempts_identifier_type ON public.login_attempts(identifier_type);
CREATE INDEX IF NOT EXISTS idx_login_attempts_blocked_until ON public.login_attempts(blocked_until);
CREATE INDEX IF NOT EXISTS idx_login_attempts_last_attempt ON public.login_attempts(last_attempt_at);

-- Composite index for common queries
CREATE INDEX IF NOT EXISTS idx_login_attempts_identifier_type_composite 
  ON public.login_attempts(identifier, identifier_type, blocked_until);

-- Create function to update updated_at column
CREATE OR REPLACE FUNCTION public.update_login_attempts_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Create trigger for updating updated_at
CREATE TRIGGER trigger_update_login_attempts_updated_at
  BEFORE UPDATE ON public.login_attempts
  FOR EACH ROW
  EXECUTE FUNCTION public.update_login_attempts_updated_at();

-- Enable RLS (only server-side functions should access this table)
ALTER TABLE public.login_attempts ENABLE ROW LEVEL SECURITY;

-- Create policy that only allows service role to access this table
-- This ensures only server-side code can manage login attempts
CREATE POLICY "Login attempts service access only" ON public.login_attempts
  FOR ALL
  USING (current_user = 'service_role'::name);

-- Function to check if login attempt is blocked
CREATE OR REPLACE FUNCTION public.is_login_blocked(
  p_identifier TEXT,
  p_identifier_type TEXT DEFAULT 'email'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  blocked_until_time TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Get the blocked_until time for this identifier
  SELECT blocked_until INTO blocked_until_time
  FROM public.login_attempts
  WHERE identifier = p_identifier 
    AND identifier_type = p_identifier_type
    AND blocked_until IS NOT NULL
    AND blocked_until > NOW();
  
  -- Return true if blocked, false otherwise
  RETURN blocked_until_time IS NOT NULL;
END;
$$;

-- Function to record a failed login attempt
CREATE OR REPLACE FUNCTION public.record_failed_login_attempt(
  p_identifier TEXT,
  p_identifier_type TEXT DEFAULT 'email',
  p_max_attempts INTEGER DEFAULT 5,
  p_block_duration_minutes INTEGER DEFAULT 15
)
RETURNS BOOLEAN -- Returns true if user is now blocked
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  current_record RECORD;
  new_attempt_count INTEGER;
  should_block BOOLEAN := FALSE;
  block_expiry TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Calculate block expiry time
  block_expiry := NOW() + (p_block_duration_minutes || ' minutes')::INTERVAL;
  
  -- Get existing record
  SELECT * INTO current_record
  FROM public.login_attempts
  WHERE identifier = p_identifier 
    AND identifier_type = p_identifier_type;
  
  IF current_record IS NULL THEN
    -- First failed attempt for this identifier
    INSERT INTO public.login_attempts (
      identifier, 
      identifier_type, 
      attempt_count,
      first_attempt_at,
      last_attempt_at
    ) VALUES (
      p_identifier, 
      p_identifier_type, 
      1,
      NOW(),
      NOW()
    );
    new_attempt_count := 1;
  ELSE
    -- Check if this is within the attempt window (5 minutes)
    IF (NOW() - current_record.last_attempt_at) > INTERVAL '5 minutes' THEN
      -- Reset counter if last attempt was more than 5 minutes ago
      UPDATE public.login_attempts
      SET 
        attempt_count = 1,
        first_attempt_at = NOW(),
        last_attempt_at = NOW(),
        blocked_until = NULL
      WHERE identifier = p_identifier 
        AND identifier_type = p_identifier_type;
      new_attempt_count := 1;
    ELSE
      -- Increment attempt counter
      new_attempt_count := current_record.attempt_count + 1;
      
      -- Check if we should block the user
      IF new_attempt_count >= p_max_attempts THEN
        should_block := TRUE;
        UPDATE public.login_attempts
        SET 
          attempt_count = new_attempt_count,
          last_attempt_at = NOW(),
          blocked_until = block_expiry
        WHERE identifier = p_identifier 
          AND identifier_type = p_identifier_type;
      ELSE
        UPDATE public.login_attempts
        SET 
          attempt_count = new_attempt_count,
          last_attempt_at = NOW()
        WHERE identifier = p_identifier 
          AND identifier_type = p_identifier_type;
      END IF;
    END IF;
  END IF;
  
  RETURN should_block;
END;
$$;

-- Function to clear login attempts after successful login
CREATE OR REPLACE FUNCTION public.clear_login_attempts(
  p_identifier TEXT,
  p_identifier_type TEXT DEFAULT 'email'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  DELETE FROM public.login_attempts
  WHERE identifier = p_identifier 
    AND identifier_type = p_identifier_type;
END;
$$;

-- Function to get remaining block time in seconds
CREATE OR REPLACE FUNCTION public.get_login_block_remaining_seconds(
  p_identifier TEXT,
  p_identifier_type TEXT DEFAULT 'email'
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  blocked_until_time TIMESTAMP WITH TIME ZONE;
  remaining_seconds INTEGER;
BEGIN
  -- Get the blocked_until time for this identifier
  SELECT blocked_until INTO blocked_until_time
  FROM public.login_attempts
  WHERE identifier = p_identifier 
    AND identifier_type = p_identifier_type
    AND blocked_until IS NOT NULL
    AND blocked_until > NOW();
  
  IF blocked_until_time IS NULL THEN
    RETURN 0;
  END IF;
  
  -- Calculate remaining seconds
  remaining_seconds := EXTRACT(EPOCH FROM (blocked_until_time - NOW()));
  
  RETURN GREATEST(0, remaining_seconds);
END;
$$;

-- Function to cleanup old login attempts (for maintenance)
CREATE OR REPLACE FUNCTION public.cleanup_old_login_attempts(
  days_to_keep INTEGER DEFAULT 30
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM public.login_attempts 
  WHERE created_at < NOW() - (days_to_keep || ' days')::INTERVAL;
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  RETURN format('Deleted %s old login attempt records', deleted_count);
END;
$$;

-- Add helpful comments
COMMENT ON TABLE public.login_attempts IS 'Tracks failed login attempts for brute force protection';
COMMENT ON COLUMN public.login_attempts.identifier IS 'Email address or IP address being tracked';
COMMENT ON COLUMN public.login_attempts.identifier_type IS 'Type of identifier: email or ip';
COMMENT ON COLUMN public.login_attempts.attempt_count IS 'Number of failed attempts within the current window';
COMMENT ON COLUMN public.login_attempts.blocked_until IS 'Timestamp until which the identifier is blocked (NULL if not blocked)';

-- Log the completion
DO $$
BEGIN
  RAISE NOTICE 'Login attempts table and brute force protection functions have been created successfully';
  RAISE NOTICE 'Functions available: is_login_blocked, record_failed_login_attempt, clear_login_attempts, get_login_block_remaining_seconds';
  RAISE NOTICE 'Default settings: Max 5 attempts, 15 minute block duration, 5 minute attempt window';
END $$;
