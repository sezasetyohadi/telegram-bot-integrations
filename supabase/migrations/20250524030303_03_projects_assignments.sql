-- ============================================================================
-- SECTION: PROJECT ASSIGNMENTS
-- ============================================================================


-- Table: project_assignments
CREATE TABLE public.project_assignments (
  id SERIAL PRIMARY KEY,
  project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  assigned_to UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, 
  assigned_by UUID NOT NULL REFERENCES auth.users(id),
  assigned_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  UNIQUE(project_id, assigned_to)
);

-- Helper function: is_waspang (optimized)
CREATE OR REPLACE FUNCTION is_waspang(user_id UUID) 
RETURNS BOOLEAN 
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles ur
    JOIN public.roles r ON ur.role_id = r.id
    WHERE ur.user_id = $1 AND r.name = 'waspang'
  );
$$;

-- Helper function: is_admin (optimized)
CREATE OR REPLACE FUNCTION is_admin(user_id UUID) 
RETURNS BOOLEAN 
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = '' AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles ur
    JOIN public.roles r ON ur.role_id = r.id
    WHERE ur.user_id = $1 AND r.name = 'admin'
  );
$$;

-- Optimized function to check if current user is admin
CREATE OR REPLACE FUNCTION public.current_user_is_admin()
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT public.current_user_is_any_admin();
$$;

-- Optimized function to check if current user has project access
CREATE OR REPLACE FUNCTION public.user_has_project_access(project_id INTEGER)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.project_assignments pa
    WHERE pa.project_id = $1 AND pa.assigned_to = public.current_user_id()
  );
$$;


-- Function: check_project_assignment_roles
CREATE OR REPLACE FUNCTION check_project_assignment_roles()
RETURNS TRIGGER AS $$
DECLARE
  assigned_by_role TEXT;
  user_role TEXT;
BEGIN
  SELECT r.name INTO assigned_by_role
  FROM public.user_roles ur
  JOIN public.roles r ON ur.role_id = r.id
  WHERE ur.user_id = NEW.assigned_by;
  
  IF assigned_by_role != 'admin' THEN
    RAISE EXCEPTION 'Only admin users can assign projects';
  END IF;
  
  SELECT r.name INTO user_role
  FROM public.user_roles ur
  JOIN public.roles r ON ur.role_id = r.id
  WHERE ur.user_id = NEW.assigned_to;
  
  -- Allow both waspang and admin users to be assigned to projects
  IF user_role NOT IN ('waspang', 'admin') THEN
    RAISE EXCEPTION 'Only waspang and admin users can be assigned to projects';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Trigger: enforce_project_assignment_roles
CREATE TRIGGER enforce_project_assignment_roles
BEFORE INSERT OR UPDATE ON public.project_assignments
FOR EACH ROW EXECUTE FUNCTION check_project_assignment_roles();

-- View: project_assignments_view (secured - no direct auth.users exposure)
CREATE OR REPLACE VIEW public.project_assignments_view
WITH (security_invoker=on) AS
SELECT 
  pa.id,
  p.id AS project_id,
  p.name AS project_name,
  pa.assigned_to AS user_id,
  ur_user.user_name AS user_name,
  ur_user.role_name AS user_role,
  ur_admin.user_name AS assigned_by_name,
  ur_admin.role_name AS assigned_by_role,
  pa.assigned_at
FROM 
  public.project_assignments pa
JOIN 
  projects p ON pa.project_id = p.id
LEFT JOIN
  (SELECT ur.user_id, ur.user_name, r.name AS role_name 
   FROM public.user_roles ur 
   JOIN public.roles r ON ur.role_id = r.id) ur_user ON pa.assigned_to = ur_user.user_id
LEFT JOIN
  (SELECT ur.user_id, ur.user_name, r.name AS role_name 
   FROM public.user_roles ur 
   JOIN public.roles r ON ur.role_id = r.id) ur_admin ON pa.assigned_by = ur_admin.user_id;

-- Enable RLS on project_assignments table
ALTER TABLE public.project_assignments ENABLE ROW LEVEL SECURITY;

-- Drop ALL existing policies for project_assignments to avoid duplicates
DROP POLICY IF EXISTS "Users can view their own assignments" ON public.project_assignments;
DROP POLICY IF EXISTS "Admins can view all assignments" ON public.project_assignments;
DROP POLICY IF EXISTS "Admins can manage assignments" ON public.project_assignments;
DROP POLICY IF EXISTS "Project assignments unified access policy" ON public.project_assignments;

-- Single consolidated policy for project_assignments (will be created in 06_rls_policies.sql)
-- Note: Policies are handled in 06_rls_policies.sql to avoid duplicates

-- Function: project_has_assignments
CREATE OR REPLACE FUNCTION project_has_assignments(project_id INTEGER) 
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.project_assignments pa
    WHERE pa.project_id = $1
  );
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Function: enforce_project_assignment_exists
CREATE OR REPLACE FUNCTION enforce_project_assignment_exists()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF NOT public.project_has_assignments(OLD.project_id) THEN
      RAISE EXCEPTION 'Cannot remove the last assignment from a project. Projects must have at least one assigned user.';
    END IF;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Trigger: prevent_unassigned_projects
CREATE TRIGGER prevent_unassigned_projects
AFTER DELETE ON public.project_assignments
FOR EACH ROW EXECUTE FUNCTION enforce_project_assignment_exists();

-- Function: enforce_project_must_have_assignment
CREATE OR REPLACE FUNCTION enforce_project_must_have_assignment()
RETURNS TRIGGER AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.project_assignments pa
    WHERE pa.project_id = NEW.id
  ) THEN
    RAISE EXCEPTION 'Projects must be assigned to at least one waspang user immediately upon creation.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Trigger: ensure_project_has_assignment
CREATE CONSTRAINT TRIGGER ensure_project_has_assignment
AFTER INSERT ON projects
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION enforce_project_must_have_assignment();

-- Note: Project RLS policies are handled in 06_rls_policies.sql