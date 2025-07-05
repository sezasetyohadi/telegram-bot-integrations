-- ============================================================================
-- PROJECT TYPE TABLE
-- Created: 2025-06-03
-- ============================================================================

-- Table: project_types
CREATE TABLE public.project_types (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Add index for better performance
CREATE INDEX IF NOT EXISTS idx_project_types_name ON project_types(name);

-- Insert initial data
INSERT INTO public.project_types (name) VALUES 
  ('AERIAL'),
  ('UNDERGROUND');

-- Add foreign key to projects table
ALTER TABLE public.projects 
  ADD COLUMN project_type_id INTEGER REFERENCES public.project_types(id);

-- Add index for the foreign key
CREATE INDEX IF NOT EXISTS idx_projects_project_type_id ON projects(project_type_id);

-- Create a function to update the updated_at column
CREATE OR REPLACE FUNCTION update_project_types_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Create a trigger to automatically update the updated_at column
CREATE TRIGGER update_project_types_updated_at
BEFORE UPDATE ON public.project_types
FOR EACH ROW
EXECUTE FUNCTION update_project_types_updated_at();

-- Create RLS policies
ALTER TABLE public.project_types ENABLE ROW LEVEL SECURITY;

-- Drop ALL existing policies
DROP POLICY IF EXISTS "Everyone can view project types" ON public.project_types;
DROP POLICY IF EXISTS "Only admins can insert project types" ON public.project_types;
DROP POLICY IF EXISTS "Only admins can update project_types" ON public.project_types;
DROP POLICY IF EXISTS "Only admins can delete project types" ON public.project_types;
DROP POLICY IF EXISTS "Project types view policy" ON public.project_types;
DROP POLICY IF EXISTS "Project types admin policy" ON public.project_types;
DROP POLICY IF EXISTS "Project types select policy" ON public.project_types;
DROP POLICY IF EXISTS "Project types modify policy" ON public.project_types;

-- Single consolidated policy that handles both SELECT (public) and modifications (admin only)
CREATE POLICY "Project types access policy" ON public.project_types
  FOR ALL 
  USING (
    -- Allow SELECT for everyone, but require admin for INSERT/UPDATE/DELETE
    CASE 
      WHEN current_setting('request.method', true) = 'GET' THEN true
      ELSE public.current_user_is_any_admin()
    END
  );