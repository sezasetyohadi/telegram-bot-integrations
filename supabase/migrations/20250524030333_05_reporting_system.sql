-- ============================================================================
-- MAIN TABLES
-- ============================================================================

-- Table 1: Report Categories (DISTRIBUTION, SUBFEEDER)
CREATE TABLE public.report_categories (
  id SERIAL PRIMARY KEY,
  category_name VARCHAR(50) NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table 2: Report Parent Items (for grouping items under titles)
CREATE TABLE public.report_parent_items (
  id SERIAL PRIMARY KEY,
  project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  parent_title TEXT NOT NULL,
  category_id INTEGER NOT NULL REFERENCES report_categories(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(project_id, parent_title, category_id)
);

-- Table 3: Report Items (connected to parent items)
CREATE TABLE public.report_items (
  id SERIAL PRIMARY KEY,
  project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  parent_item_id INTEGER REFERENCES report_parent_items(id) ON DELETE CASCADE, -- Made nullable for flexibility
  category_id INTEGER NOT NULL REFERENCES report_categories(id) ON DELETE CASCADE,
  item_title TEXT NOT NULL,
  planned_quantity DECIMAL(10,2) DEFAULT 0, -- value_x (kuantitas yang direncanakan)
  created_by TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table 4: Implementation Records (for tracking daily progress)
CREATE TABLE public.report_implementations (
  id SERIAL PRIMARY KEY,
  report_item_id INTEGER NOT NULL REFERENCES report_items(id) ON DELETE CASCADE,
  daily_quantity DECIMAL(10,2) DEFAULT 0, -- value_z (kuantitas hari ini)
  implementation_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- TEMPLATE SYSTEM
-- ============================================================================

-- Table 5: Report Templates
CREATE TABLE public.report_templates (
  id SERIAL PRIMARY KEY,
  template_name TEXT NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table 6: Template Parent Items (for organizing template structure)
CREATE TABLE public.report_templates_parent_items (
  id SERIAL PRIMARY KEY,
  template_id INTEGER NOT NULL REFERENCES report_templates(id) ON DELETE CASCADE,
  item_parent_title TEXT NOT NULL,
  category_id INTEGER NOT NULL REFERENCES report_categories(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(template_id, item_parent_title)
);

-- Table 7: Template Items (for creating new reports)
CREATE TABLE public.report_template_items (
  id SERIAL PRIMARY KEY,
  template_id INTEGER NOT NULL REFERENCES report_templates(id) ON DELETE CASCADE,
  template_parent_item_id INTEGER REFERENCES report_templates_parent_items(id) ON DELETE CASCADE, -- nullable to allow independent items
  category_id INTEGER NOT NULL REFERENCES report_categories(id) ON DELETE CASCADE,
  item_title TEXT NOT NULL,
  default_planned_quantity DECIMAL(10,2) DEFAULT 0, -- default value_x
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- ADDITIONAL TABLES
-- ============================================================================

-- Table 8: Report Issues
CREATE TABLE public.report_issues (
  id SERIAL PRIMARY KEY,
  project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  issue_description TEXT NOT NULL,
  report_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table 9: Tomorrow's Plans
CREATE TABLE public.report_tomorrow_plans (
  id SERIAL PRIMARY KEY,
  project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  report_date DATE NOT NULL DEFAULT CURRENT_DATE,
  plan_description TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Table 10: ATP Plans (with specific columns for civil work and OPM test)
CREATE TABLE public.report_atp (
  id SERIAL PRIMARY KEY,
  project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  report_date DATE NOT NULL DEFAULT CURRENT_DATE,
  civil_work DATE,
  opm_test DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(project_id, report_date)
);

-- Table 11: Work Time Logs
CREATE TABLE public.report_work_time (
  id SERIAL PRIMARY KEY,
  project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  report_date DATE NOT NULL DEFAULT CURRENT_DATE,
  start_time TIME,
  end_time TIME,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(project_id, report_date)
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Indexes for new table structure
CREATE INDEX IF NOT EXISTS idx_report_categories_name ON report_categories(category_name);
CREATE INDEX IF NOT EXISTS idx_report_parent_items_project_id ON report_parent_items(project_id);
CREATE INDEX IF NOT EXISTS idx_report_parent_items_category ON report_parent_items(category_id);
CREATE INDEX IF NOT EXISTS idx_report_items_parent_id ON report_items(parent_item_id);
CREATE INDEX IF NOT EXISTS idx_report_items_category_id ON report_items(category_id);

-- Keep the most important implementation index (this is heavily used)
CREATE INDEX IF NOT EXISTS idx_implementations_item_date ON report_implementations(report_item_id, implementation_date);

-- Essential template indexes (keep these as they'll be used)
CREATE INDEX IF NOT EXISTS idx_template_items_template_id ON report_template_items(template_id);
CREATE INDEX IF NOT EXISTS idx_template_parent_items_template_id ON report_templates_parent_items(template_id);
CREATE INDEX IF NOT EXISTS idx_template_items_template_parent_id ON report_template_items(template_parent_item_id);
CREATE INDEX IF NOT EXISTS idx_template_items_category_id ON report_template_items(category_id);

-- Optimized composite indexes for date-based queries
CREATE INDEX IF NOT EXISTS idx_report_issues_project_date ON report_issues(project_id, report_date);
CREATE INDEX IF NOT EXISTS idx_tomorrow_plans_project_date ON report_tomorrow_plans(project_id, report_date);
CREATE INDEX IF NOT EXISTS idx_atp_project_date ON report_atp(project_id, report_date);
CREATE INDEX IF NOT EXISTS idx_work_time_project_date ON report_work_time(project_id, report_date);

-- ============================================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Function to update parent item quantities (placeholder, can be expanded later)
CREATE OR REPLACE FUNCTION update_parent_quantities()
RETURNS TRIGGER AS $$
BEGIN
  -- Logika untuk memperbarui item induk dapat ditambahkan di sini jika diperlukan di masa mendatang.
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Trigger to update parent quantities when child items change
CREATE TRIGGER trigger_update_parent_quantities
  AFTER INSERT OR UPDATE ON report_items
  FOR EACH ROW
  EXECUTE FUNCTION update_parent_quantities();

-- ============================================================================
-- HELPER FUNCTIONS FOR QUERIES
-- ============================================================================

-- Function to get today's report for a project
CREATE OR REPLACE FUNCTION get_todays_report(p_project_id INTEGER)
RETURNS TABLE (
  item_id INTEGER,
  parent_item_id INTEGER,
  item_title TEXT,
  planned_quantity DECIMAL(10,2),
  total_quantity_to_date DECIMAL(10,2),
  todays_quantity DECIMAL(10,2)
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ri.id as item_id,
    ri.parent_item_id,
    ri.item_title,
    ri.planned_quantity,
    -- Menghitung total kuantitas (value_y) dari seluruh implementasi hingga saat ini
    COALESCE((
      SELECT SUM(impl_all.daily_quantity)
      FROM public.report_implementations impl_all
      WHERE impl_all.report_item_id = ri.id
    ), 0) as total_quantity_to_date,
    -- Menghitung kuantitas hari ini (value_z)
    COALESCE((
        SELECT SUM(impl_today.daily_quantity)
        FROM public.report_implementations impl_today
        WHERE impl_today.report_item_id = ri.id
          AND impl_today.implementation_date = CURRENT_DATE
    ), 0) as todays_quantity
  FROM public.report_items ri
  LEFT JOIN public.report_parent_items rpi ON ri.parent_item_id = rpi.id
  WHERE rpi.project_id = p_project_id
  ORDER BY ri.id;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Function to get historical report data for a specific date
-- Add this new function after the existing helper functions
CREATE OR REPLACE FUNCTION get_historical_report_with_details(p_project_id INTEGER, p_date DATE)
RETURNS TABLE (
  item_id INTEGER,
  parent_item_id INTEGER,
  category_id INTEGER,
  item_title TEXT,
  planned_quantity DECIMAL(10,2), -- x value
  cumulative_quantity DECIMAL(10,2), -- y value
  daily_quantity DECIMAL(10,2), -- z value
  parent_title TEXT,
  category_name VARCHAR(50)
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ri.id as item_id,
    ri.parent_item_id,
    ri.category_id,
    ri.item_title,
    ri.planned_quantity, -- x: planned quantity
    -- y: cumulative quantity up to and including selected date
    COALESCE((
      SELECT SUM(impl.daily_quantity)
      FROM public.report_implementations impl
      WHERE impl.report_item_id = ri.id
        AND impl.implementation_date <= p_date
    ), 0) as cumulative_quantity,
    -- z: daily quantity for the exact selected date
    COALESCE((
      SELECT SUM(impl.daily_quantity)
      FROM public.report_implementations impl
      WHERE impl.report_item_id = ri.id
        AND impl.implementation_date = p_date
    ), 0) as daily_quantity,
    rpi.parent_title,
    rc.category_name
  FROM public.report_items ri
  LEFT JOIN public.report_parent_items rpi ON ri.parent_item_id = rpi.id
  LEFT JOIN public.report_categories rc ON ri.category_id = rc.id
  WHERE rpi.project_id = p_project_id
  ORDER BY ri.id;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Function to get available implementation dates for a project
CREATE OR REPLACE FUNCTION get_project_implementation_dates(p_project_id INTEGER)
RETURNS TABLE (
  implementation_date DATE
) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT ri.implementation_date
  FROM public.report_implementations ri
  LEFT JOIN public.report_items rep_items ON ri.report_item_id = rep_items.id
  LEFT JOIN public.report_parent_items rpi ON rep_items.parent_item_id = rpi.id
  WHERE rpi.project_id = p_project_id
  ORDER BY implementation_date DESC;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Insert default categories
INSERT INTO report_categories (category_name) VALUES
('DISTRIBUTION'),
('SUBFEEDER');

-- Insert default template
INSERT INTO report_templates (template_name, description) VALUES
('Default Template', 'Template default untuk laporan proyek');

-- Enable RLS on report_parent_items table (missing RLS enablement)
ALTER TABLE report_parent_items ENABLE ROW LEVEL SECURITY;