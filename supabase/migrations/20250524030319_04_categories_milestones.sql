-- ============================================================================
-- SECTION: CATEGORIES AND MILESTONES
-- ============================================================================

-- Table: categories
CREATE TABLE categories (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: project_categories
CREATE TABLE project_categories (
  id SERIAL PRIMARY KEY,
  project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  UNIQUE(project_id, category_id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: milestones
CREATE TABLE milestones (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  project TEXT NOT NULL, 
  project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  category_id INTEGER REFERENCES categories(id) ON DELETE CASCADE, 
  photo_needed INTEGER NOT NULL DEFAULT 0,
  photos_uploaded INTEGER NOT NULL DEFAULT 0
);

-- OPTIMIZATION: Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_milestones_project_id ON milestones(project_id);
CREATE INDEX IF NOT EXISTS idx_milestones_category_id ON milestones(category_id);
CREATE INDEX IF NOT EXISTS idx_milestones_project_category ON milestones(project_id, category_id);
CREATE INDEX IF NOT EXISTS idx_milestones_id_project ON milestones(id, project_id);

-- Table: milestone_templates
CREATE TABLE milestone_templates (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  photo_needed INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS on categories table for security
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Consolidated policy for categories
CREATE POLICY "Categories access policy" ON categories
  FOR ALL
  USING (
    public.current_user_is_any_admin()
    OR public.current_user_role() = 'authenticated'
  );

-- Enable RLS on milestones table
ALTER TABLE milestones ENABLE ROW LEVEL SECURITY;

-- Drop ALL existing policies for milestones (including variations)
DO $$
DECLARE
    pol_name TEXT;
BEGIN
    FOR pol_name IN 
        SELECT policyname FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'milestones'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS "%s" ON milestones', pol_name);
    END LOOP;
END $$;

-- Single consolidated policy for milestones (ensure it's created properly)
CREATE POLICY "Milestones access policy" ON milestones
  FOR ALL
  USING (
    -- Allow service role for API calls
    current_user = 'service_role'::name
    OR current_user = 'authenticator'::name
    OR public.current_user_is_any_admin()
    OR public.user_has_project_access(milestones.project_id)
    -- Allow authenticated users when auth context is available
    OR (auth.uid() IS NOT NULL)
  );

-- Enable RLS on project_categories table
ALTER TABLE project_categories ENABLE ROW LEVEL SECURITY;

-- Single consolidated policy for project_categories
CREATE POLICY "Project categories unified access policy" ON project_categories
  FOR ALL
  USING (
    public.current_user_is_any_admin()
    OR public.user_has_project_access(project_categories.project_id)
  );

-- Enable RLS on milestone_templates table
ALTER TABLE milestone_templates ENABLE ROW LEVEL SECURITY;

-- Single consolidated policy for milestone_templates
CREATE POLICY "Milestone templates unified access policy" ON milestone_templates
  FOR ALL
  USING (
    public.current_user_is_any_admin()
    OR public.current_user_role() = 'authenticated'
  );