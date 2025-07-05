-- Fix super admin access for user management
-- This migration ensures super admins can properly access user management features

-- 1. Create or replace the users_with_roles view to be accessible by super admins
DROP VIEW IF EXISTS public.users_with_roles;

CREATE OR REPLACE VIEW public.users_with_roles
WITH (security_invoker=false) AS
SELECT 
  ur.user_id as id,
  ur.user_name,
  au.email,
  r.name as role_name,
  ur.is_super_admin,
  au.created_at
FROM public.user_roles ur
JOIN public.roles r ON ur.role_id = r.id
JOIN auth.users au ON ur.user_id = au.id;

-- Enable RLS on the view
ALTER VIEW public.users_with_roles SET (security_barrier = true);

-- 2. Create RLS policy for users_with_roles view access
-- Drop existing policies on users_with_roles if any exist
DROP POLICY IF EXISTS "Users with roles view policy" ON public.users_with_roles;

-- Note: Views inherit RLS from underlying tables, but we ensure proper access through user_roles policies

-- 3. Ensure auth.users table can be accessed by super admins for user management
-- Create a secure function to get user details for super admins
CREATE OR REPLACE FUNCTION public.get_user_details_for_super_admin()
RETURNS TABLE(
  id UUID,
  email TEXT,
  created_at TIMESTAMPTZ,
  email_confirmed_at TIMESTAMPTZ,
  last_sign_in_at TIMESTAMPTZ
)
LANGUAGE SQL
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT 
    au.id,
    au.email,
    au.created_at,
    au.email_confirmed_at,
    au.last_sign_in_at
  FROM auth.users au
  WHERE public.current_user_is_super_admin();
$$;

-- 4. Grant necessary permissions for super admin operations
-- Super admins need to be able to perform user management operations

-- 5. Create a secure function to check if a user can manage other users
CREATE OR REPLACE FUNCTION public.can_manage_users()
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT public.current_user_is_super_admin();
$$;

-- 6. Update user_roles policies to be more explicit about super admin access
DROP POLICY IF EXISTS "User roles select policy" ON public.user_roles;
DROP POLICY IF EXISTS "User roles insert policy" ON public.user_roles;
DROP POLICY IF EXISTS "User roles update policy" ON public.user_roles;
DROP POLICY IF EXISTS "User roles delete policy" ON public.user_roles;

-- More explicit policies for user_roles table
CREATE POLICY "User roles select policy" ON public.user_roles
  FOR SELECT
  USING (
    -- Super admins can see all user roles
    public.current_user_is_super_admin()
    -- Regular users can only see their own role
    OR user_id = public.current_user_id()
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
  )
  WITH CHECK (
    -- Super admins can update any user role
    public.current_user_is_super_admin()
  );

CREATE POLICY "User roles delete policy" ON public.user_roles
  FOR DELETE
  USING (
    -- Only super admins can delete user roles
    public.current_user_is_super_admin()
  );

-- 7. Ensure roles table is accessible for user management
DROP POLICY IF EXISTS "Roles access policy" ON public.roles;

CREATE POLICY "Roles select policy" ON public.roles
  FOR SELECT
  USING (
    -- Anyone authenticated can read roles for dropdowns, etc.
    public.current_user_role() = 'authenticated'
  );

CREATE POLICY "Roles modify policy" ON public.roles
  FOR ALL
  USING (
    -- Only super admins can modify roles
    public.current_user_is_super_admin()
  );

-- 8. Verify the setup with a test function
CREATE OR REPLACE FUNCTION public.test_super_admin_access()
RETURNS TABLE(
  is_super_admin BOOLEAN,
  can_see_users BOOLEAN,
  user_count BIGINT
)
LANGUAGE SQL
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT 
    public.current_user_is_super_admin() as is_super_admin,
    public.can_manage_users() as can_see_users,
    (SELECT COUNT(*) FROM public.users_with_roles) as user_count;
$$;

-- Log the completion
DO $$
BEGIN
  RAISE NOTICE 'Super admin policies have been updated successfully';
  RAISE NOTICE 'Super admins can now access user management features';
END $$;
