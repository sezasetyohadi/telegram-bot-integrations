-- ============================================================================
-- SECTION: AUTH SYSTEM
-- ============================================================================

-- Table: roles
CREATE TABLE public.roles (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT
);

-- Insert default roles
INSERT INTO public.roles (name, description) VALUES 
  ('admin', 'Administrator with full access'),
  ('waspang', 'Waspang user with limited access');

-- Table: user_roles
CREATE TABLE public.user_roles (
  id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role_id INTEGER NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
  user_name TEXT NOT NULL,
  is_super_admin BOOLEAN DEFAULT false,
  UNIQUE(user_id, role_id)
);

-- Performance optimized auth functions
CREATE OR REPLACE FUNCTION public.current_user_id()
RETURNS UUID
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT auth.role();
$$;

-- Enhanced function to check if current user is super admin
CREATE OR REPLACE FUNCTION public.current_user_is_super_admin()
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles ur
    JOIN public.roles r ON ur.role_id = r.id
    WHERE ur.user_id = public.current_user_id() 
    AND r.name = 'admin' 
    AND ur.is_super_admin = true
  );
$$;

-- Enhanced function to check if user is any admin (including super admin)
CREATE OR REPLACE FUNCTION public.current_user_is_any_admin()
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles ur
    JOIN public.roles r ON ur.role_id = r.id
    WHERE ur.user_id = public.current_user_id() 
    AND r.name = 'admin'
  );
$$;

-- Function: handle_new_user
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
DECLARE
  default_role_id INTEGER;
BEGIN
  SELECT id INTO default_role_id FROM public.roles WHERE name = 'waspang';
  INSERT INTO public.user_roles (user_id, role_id, user_name)
  VALUES (NEW.id, default_role_id, NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = '';

-- Trigger: on_auth_user_created
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- View: users_with_roles (secured - with auth.users access via security_definer)
CREATE OR REPLACE VIEW public.users_with_roles
WITH (security_invoker=false) AS
SELECT 
  ur.user_id as id,
  ur.user_name,
  au.email,
  r.name as role_name,
  ur.is_super_admin
FROM public.user_roles ur
JOIN public.roles r ON ur.role_id = r.id
JOIN auth.users au ON ur.user_id = au.id;

-- Enable security barrier on users_with_roles view
ALTER VIEW public.users_with_roles SET (security_barrier = true);

-- Enable RLS on user_roles table
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- Enable RLS on roles table for security
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;

-- Consolidated policy for roles
CREATE POLICY "Roles access policy" ON public.roles
  FOR ALL
  USING (public.current_user_role() = 'authenticated');

-- Drop existing user_roles policies
DROP POLICY IF EXISTS "User roles access policy" ON public.user_roles;

-- Enhanced RLS policies for user_roles table
CREATE POLICY "User roles select policy" ON public.user_roles
  FOR SELECT
  USING (
    -- Super admins can see all user roles
    public.current_user_is_super_admin()
    -- Regular users can only see their own role
    OR user_id = public.current_user_id()
    -- Any authenticated user can see basic info (for role checks)
    OR public.current_user_role() = 'authenticated'
  );

CREATE POLICY "User roles insert policy" ON public.user_roles
  FOR INSERT
  WITH CHECK (
    -- Only super admins can create new user roles
    public.current_user_is_super_admin()
  );

CREATE POLICY "User roles update policy" ON public.user_roles
  FOR UPDATE
  USING (
    -- Super admins can update any user role
    public.current_user_is_super_admin()
    -- Users can update their own user_name only
    OR user_id = public.current_user_id()
  )
  WITH CHECK (
    -- Super admins can update any user role
    public.current_user_is_super_admin()
    -- Regular users can only update their own name (role and super_admin status cannot be changed)
    OR (user_id = public.current_user_id())
  );

CREATE POLICY "User roles delete policy" ON public.user_roles
  FOR DELETE
  USING (
    -- Only super admins can delete user roles
    public.current_user_is_super_admin()
  );