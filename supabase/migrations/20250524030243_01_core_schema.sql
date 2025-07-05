-- ============================================================================
-- SECTION: CORE SCHEMA
-- ============================================================================

-- Table: projects
CREATE TABLE projects (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  location TEXT NOT NULL,
  start_date TIMESTAMP NOT NULL,
  end_date TIMESTAMP NOT NULL,
  is_completed BOOLEAN NOT NULL DEFAULT false,
  description TEXT,
  project_type TEXT NOT NULL,
  latitude NUMERIC,
  longitude NUMERIC,
  homepass INTEGER NOT NULL,
  man_power INTEGER NOT NULL DEFAULT 0,
  jointer INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS on core tables
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
