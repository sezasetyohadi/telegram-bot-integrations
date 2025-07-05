-- ============================================================================
-- SECTION: RLS POLICIES
-- ============================================================================

-- Drop ALL existing policies to ensure clean state
DO $$
DECLARE
    pol_name TEXT;
    table_names TEXT[] := ARRAY[
        'projects', 'project_assignments', 'report_items', 
        'report_implementations', 'report_template_items', 'report_issues',
        'report_tomorrow_plans', 'report_atp', 'report_categories', 
        'report_parent_items', 'report_work_time', 'report_templates_parent_items',
        'project_categories', 'milestone_templates', 'report_templates'
    ];
    tbl_name TEXT;
BEGIN
    -- Note: Exclude 'milestones' from this list as its policy is handled in 04_categories_milestones.sql
    FOREACH tbl_name IN ARRAY table_names LOOP
        -- Drop all policies for each table
        FOR pol_name IN 
            SELECT policyname FROM pg_policies 
            WHERE schemaname = 'public' AND tablename = tbl_name
        LOOP
            EXECUTE format('DROP POLICY IF EXISTS "%s" ON %s', pol_name, tbl_name);
        END LOOP;
    END LOOP;
END $$;

-- RLS for projects
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Projects access policy" ON projects
  FOR ALL
  USING (
    public.current_user_is_any_admin() 
    OR public.user_has_project_access(projects.id)
  );

-- RLS for milestones is already handled in 04_categories_milestones.sql
-- Skip to avoid conflict

-- Enable RLS on all reporting tables
ALTER TABLE report_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_implementations ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_template_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_tomorrow_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_work_time ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_atp ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_templates_parent_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE report_parent_items ENABLE ROW LEVEL SECURITY;

-- Performance optimized functions
CREATE OR REPLACE FUNCTION public.user_has_report_item_access(item_id INTEGER)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.report_items ri
    LEFT JOIN public.report_parent_items rpi ON ri.parent_item_id = rpi.id
    LEFT JOIN public.project_assignments pa ON (rpi.project_id = pa.project_id OR ri.project_id = pa.project_id)
    WHERE ri.id = $1 AND pa.assigned_to = public.current_user_id()
  );
$$;

CREATE OR REPLACE FUNCTION public.user_has_report_parent_access(parent_item_id INTEGER)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.report_parent_items rpi
    JOIN public.project_assignments pa ON rpi.project_id = pa.project_id
    WHERE rpi.id = $1 AND pa.assigned_to = public.current_user_id()
  );
$$;

-- Single consolidated policies for all tables
CREATE POLICY "Report items access policy" ON report_items
  FOR ALL
  USING (
    -- Allow service role for API calls
    current_user = 'service_role'::name
    OR current_user = 'authenticator'::name
    OR public.current_user_is_any_admin()
    OR public.user_has_report_parent_access(report_items.parent_item_id)
    OR public.user_has_project_access(report_items.project_id)
    -- Allow authenticated users when auth context is available
    OR (auth.uid() IS NOT NULL)
  );

CREATE POLICY "Report implementations access policy" ON report_implementations
  FOR ALL
  USING (
    public.current_user_is_any_admin()
    OR public.user_has_report_item_access(report_implementations.report_item_id)
  );

CREATE POLICY "Report template items access policy" ON report_template_items
  FOR ALL
  USING (
    public.current_user_is_any_admin()
    OR public.current_user_role() = 'authenticated'
  );

CREATE POLICY "Report issues access policy" ON report_issues
  FOR ALL
  USING (
    public.current_user_is_any_admin()
    OR public.user_has_project_access(report_issues.project_id)
  );

CREATE POLICY "Report tomorrow plans access policy" ON report_tomorrow_plans
  FOR ALL
  USING (
    public.current_user_is_any_admin()
    OR public.user_has_project_access(report_tomorrow_plans.project_id)
  );

CREATE POLICY "Report atp access policy" ON report_atp
  FOR ALL
  USING (
    public.current_user_is_any_admin()
    OR public.user_has_project_access(report_atp.project_id)
  );

CREATE POLICY "Report categories access policy" ON report_categories
  FOR ALL
  USING (
    public.current_user_is_any_admin()
    OR public.current_user_role() = 'authenticated'
  );

CREATE POLICY "Report parent items access policy" ON report_parent_items
  FOR ALL
  USING (
    -- Allow service role for API calls
    current_user = 'service_role'::name
    OR current_user = 'authenticator'::name
    OR public.current_user_is_any_admin()
    OR public.current_user_role() = 'authenticated'
    -- Allow authenticated users when auth context is available
    OR (auth.uid() IS NOT NULL)
  );

CREATE POLICY "Report work time access policy" ON report_work_time
  FOR ALL
  USING (
    public.current_user_is_any_admin()
    OR public.user_has_project_access(report_work_time.project_id)
  );

CREATE POLICY "Project assignments access policy" ON public.project_assignments
  FOR ALL
  USING (
    public.current_user_is_any_admin()
    OR assigned_to = public.current_user_id()
  );

CREATE POLICY "Report templates parent items access policy" ON report_templates_parent_items
  FOR ALL
  USING (
    public.current_user_is_any_admin()
    OR public.current_user_role() = 'authenticated'
  );

CREATE POLICY "Project categories access policy" ON project_categories
  FOR ALL
  USING (
    public.current_user_is_any_admin()
    OR public.user_has_project_access(project_categories.project_id)
  );

CREATE POLICY "Milestone templates access policy" ON milestone_templates
  FOR ALL
  USING (
    public.current_user_is_any_admin()
    OR public.current_user_role() = 'authenticated'
  );

CREATE POLICY "Report templates access policy" ON report_templates
  FOR ALL
  USING (
    public.current_user_is_any_admin()
    OR public.current_user_role() = 'authenticated'
  );

-- Drop duplicate index
DROP INDEX IF EXISTS idx_implementations_item_date;

-- Enhanced indexes for better performance
CREATE INDEX IF NOT EXISTS idx_report_implementations_item_date 
  ON report_implementations(report_item_id, implementation_date);

CREATE INDEX IF NOT EXISTS idx_report_implementations_date 
  ON report_implementations(implementation_date);

CREATE INDEX IF NOT EXISTS idx_report_implementations_item_id 
  ON report_implementations(report_item_id);

CREATE INDEX IF NOT EXISTS idx_report_items_project_id 
  ON report_items(project_id);

CREATE INDEX IF NOT EXISTS idx_report_items_updated_at 
  ON report_items(updated_at);

CREATE INDEX IF NOT EXISTS idx_report_implementations_updated_at 
  ON report_implementations(updated_at);

-- Composite index for common queries
CREATE INDEX IF NOT EXISTS idx_report_items_project_parent_item 
  ON report_items(project_id, parent_item_id, item_title);

-- Add updated_at triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql' SET search_path = '';

CREATE TRIGGER update_report_items_updated_at 
  BEFORE UPDATE ON report_items 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_report_implementations_updated_at 
  BEFORE UPDATE ON report_implementations 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enhanced RPC function for calculating report quantities with better performance
CREATE OR REPLACE FUNCTION calculate_report_quantities(
  p_project_id TEXT,
  p_target_date DATE
)
RETURNS TABLE(
  id TEXT,
  parent_title TEXT,
  item_title TEXT,
  cumulative_quantity NUMERIC,
  daily_quantity NUMERIC
) AS $$
BEGIN
  -- Use a single query with conditional aggregation for better performance
  RETURN QUERY
  SELECT 
    ri.id::TEXT,
    COALESCE(rpi.parent_title, 'No Parent') as parent_title,
    ri.item_title,
    COALESCE(SUM(CASE WHEN impl.implementation_date <= p_target_date THEN impl.daily_quantity ELSE 0 END), 0) as cumulative_quantity,
    COALESCE(SUM(CASE WHEN impl.implementation_date = p_target_date THEN impl.daily_quantity ELSE 0 END), 0) as daily_quantity
  FROM public.report_items ri
  LEFT JOIN public.report_parent_items rpi ON ri.parent_item_id = rpi.id
  LEFT JOIN public.report_implementations impl ON ri.id = impl.report_item_id
  WHERE ri.project_id = p_project_id::INTEGER
  GROUP BY ri.id, rpi.parent_title, ri.item_title
  ORDER BY rpi.parent_title, ri.item_title;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Add a function to get recent updates for cache invalidation
CREATE OR REPLACE FUNCTION get_recent_report_updates(
  p_project_id TEXT,
  p_since_timestamp TIMESTAMPTZ DEFAULT NOW() - INTERVAL '5 minutes'
)
RETURNS TABLE(
  item_id TEXT,
  updated_at TIMESTAMPTZ,
  update_type TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ri.id as item_id,
    ri.updated_at,
    'item_update'::TEXT as update_type
  FROM public.report_items ri
  WHERE ri.project_id = p_project_id 
    AND ri.updated_at >= p_since_timestamp
  
  UNION ALL
  
  SELECT 
    impl.report_item_id as item_id,
    impl.updated_at,
    'implementation_update'::TEXT as update_type
  FROM public.report_implementations impl
  JOIN public.report_items ri ON impl.report_item_id = ri.id
  WHERE ri.project_id = p_project_id 
    AND impl.updated_at >= p_since_timestamp
  
  ORDER BY updated_at DESC;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- ============================================================================
-- PERFORMANCE OPTIMIZATION: ADD MISSING FOREIGN KEY INDEXES
-- ============================================================================

-- Indexes for foreign keys to improve JOIN performance
CREATE INDEX IF NOT EXISTS idx_milestone_templates_category_id ON milestone_templates(category_id);
-- Remove project_activities_log indexes (table doesn't exist yet - will be added in 07_activities_system.sql)
-- CREATE INDEX IF NOT EXISTS idx_project_activities_log_project_id ON project_activities_log(project_id);
-- CREATE INDEX IF NOT EXISTS idx_project_activities_log_report_item_id ON project_activities_log(report_item_id);
-- CREATE INDEX IF NOT EXISTS idx_project_activities_log_user_id ON project_activities_log(user_id);
CREATE INDEX IF NOT EXISTS idx_project_assignments_assigned_by ON project_assignments(assigned_by);
CREATE INDEX IF NOT EXISTS idx_project_assignments_assigned_to ON project_assignments(assigned_to);
CREATE INDEX IF NOT EXISTS idx_project_assignments_project_id ON project_assignments(project_id);
CREATE INDEX IF NOT EXISTS idx_project_categories_category_id ON project_categories(category_id);
CREATE INDEX IF NOT EXISTS idx_project_categories_project_id ON project_categories(project_id);
-- Remove projects index (table doesn't have project_type_id yet - will be added in 08_project_type.sql)
-- CREATE INDEX IF NOT EXISTS idx_projects_project_type_id ON projects(project_type_id);
CREATE INDEX IF NOT EXISTS idx_report_atp_project_id ON report_atp(project_id);
CREATE INDEX IF NOT EXISTS idx_report_issues_project_id ON report_issues(project_id);
CREATE INDEX IF NOT EXISTS idx_report_templates_parent_items_category_id ON report_templates_parent_items(category_id);
CREATE INDEX IF NOT EXISTS idx_report_tomorrow_plans_project_id ON report_tomorrow_plans(project_id);
CREATE INDEX IF NOT EXISTS idx_report_work_time_project_id ON report_work_time(project_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role_id ON user_roles(role_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles(user_id);

-- ============================================================================
-- PERFORMANCE OPTIMIZATION: REMOVE UNUSED INDEXES
-- ============================================================================

-- Remove unused template-related indexes (these will be used when app grows)
-- Keep strategic indexes that will be used in queries
-- Remove only truly unused ones for template tables that are rarely queried

-- Remove some unused indexes that are truly not needed
DROP INDEX IF EXISTS idx_template_parent_items_title; -- Rarely searched by title
DROP INDEX IF EXISTS idx_project_types_name; -- Small lookup table, not worth indexing
DROP INDEX IF EXISTS idx_report_implementations_updated_at; -- Updated_at rarely queried alone
DROP INDEX IF EXISTS idx_report_items_updated_at; -- Updated_at rarely queried alone

-- Keep important indexes even if currently showing as unused:
-- - idx_milestones_project_id (will be heavily used)
-- - idx_milestone_photos_milestone_id (critical for photo queries)
-- - idx_report_items_parent_id (needed for hierarchical queries)
-- - idx_report_implementations_item_date (essential for date-based reports)

-- ============================================================================
-- PERFORMANCE OPTIMIZATION: COMPOSITE INDEXES FOR COMMON QUERIES
-- ============================================================================

-- Add composite indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_milestones_project_completion ON milestones(project_id, photos_uploaded, photo_needed);
-- Remove milestone_photos indexes (table doesn't exist yet - will be added in 09_create_milestone_photos_table.sql)
-- CREATE INDEX IF NOT EXISTS idx_milestone_photos_status_date ON milestone_photos(milestone_id, approval_status, created_at);
CREATE INDEX IF NOT EXISTS idx_report_implementations_date_item ON report_implementations(implementation_date, report_item_id);
CREATE INDEX IF NOT EXISTS idx_project_assignments_user_project ON project_assignments(assigned_to, project_id);