-- Function: create_storage_policy (secured - removed SECURITY DEFINER)
CREATE OR REPLACE FUNCTION public.create_storage_policy(
  bucket_name TEXT,
  policy_name TEXT,
  operation TEXT,
  expression TEXT
) RETURNS void AS $$
BEGIN
  -- Security check: only admins can create storage policies
  IF NOT EXISTS (
    SELECT 1 FROM public.user_roles ur
    JOIN public.roles r ON ur.role_id = r.id
    WHERE ur.user_id = auth.uid() AND r.name = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: Only administrators can create storage policies';
  END IF;
  
  EXECUTE format(
    'CREATE POLICY "%s" ON storage.objects FOR %s TO authenticated USING (%s)',
    policy_name,
    operation,
    expression
  );
EXCEPTION
  WHEN duplicate_object THEN
    EXECUTE format(
      'ALTER POLICY "%s" ON storage.objects USING (%s)',
      policy_name,
      expression
    );
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Function: exec_sql (secured - removed SECURITY DEFINER)
CREATE OR REPLACE FUNCTION public.exec_sql(sql_query text)
RETURNS void AS $$
BEGIN
  -- Security check: only admins can execute arbitrary SQL
  IF NOT EXISTS (
    SELECT 1 FROM public.user_roles ur
    JOIN public.roles r ON ur.role_id = r.id
    WHERE ur.user_id = auth.uid() AND r.name = 'admin'
  ) THEN
    RAISE EXCEPTION 'Access denied: Only administrators can execute SQL commands';
  END IF;
  
  EXECUTE sql_query;
EXCEPTION 
  WHEN duplicate_object THEN 
    NULL;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Create milestone-photos bucket early
-- NOTE: After R2 migration, this storage bucket is no longer used.
-- Kept for backward compatibility during transition.
DO $$
BEGIN
    -- Ensure storage bucket exists
    INSERT INTO storage.buckets (id, name, public)
    VALUES ('milestone-photos', 'milestone-photos', false)
    ON CONFLICT (id) DO NOTHING;
EXCEPTION 
    WHEN OTHERS THEN 
        NULL;
END $$;