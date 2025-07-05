-- PROJECT ACTIVITIES LOG SYSTEM
-- ============================================================================

-- ============================================================================
-- NEW PROJECT ACTIVITIES LOG TABLE
-- ============================================================================

CREATE TABLE project_activities_log (
  id SERIAL PRIMARY KEY,
  project_id INTEGER NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  activity_type VARCHAR(50) NOT NULL, -- 'milestone_photo_added', 'milestone_photo_deleted', 'milestone_completed', 'report_implementation_added', etc.
  activity_description TEXT NOT NULL,
  
  -- Reference data
  milestone_id INTEGER REFERENCES milestones(id) ON DELETE SET NULL,
  milestone_name VARCHAR(255),
  report_item_id INTEGER REFERENCES report_items(id) ON DELETE SET NULL,
  
  -- Photo/file related
  storage_path TEXT, -- Path to storage for preview
  photo_count_before INTEGER DEFAULT 0,
  photo_count_after INTEGER DEFAULT 0,
  
  -- Implementation related
  implementation_date DATE,
  daily_quantity DECIMAL(10,2),
  item_title TEXT,
  
  -- Metadata
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Indexes for performance
  CONSTRAINT valid_activity_type CHECK (
    activity_type IN (
      'milestone_photo_added',
      'milestone_photo_deleted', 
      'milestone_completed',
      'milestone_progress_updated',
      'report_implementation_added',
      'report_implementation_updated'
    )
  )
);

-- Indexes
CREATE INDEX idx_project_activities_log_project_date ON project_activities_log(project_id, created_at DESC);
CREATE INDEX idx_project_activities_log_type ON project_activities_log(activity_type);
CREATE INDEX idx_project_activities_log_milestone ON project_activities_log(milestone_id) WHERE milestone_id IS NOT NULL;

-- Additional foreign key indexes for performance
CREATE INDEX IF NOT EXISTS idx_project_activities_log_project_id ON project_activities_log(project_id);
CREATE INDEX IF NOT EXISTS idx_project_activities_log_report_item_id ON project_activities_log(report_item_id);
CREATE INDEX IF NOT EXISTS idx_project_activities_log_user_id ON project_activities_log(user_id);

-- ============================================================================
-- FUNCTIONS TO LOG ACTIVITIES
-- ============================================================================

-- Function to log milestone photo activities
CREATE OR REPLACE FUNCTION log_milestone_activity()
RETURNS TRIGGER AS $$
DECLARE
  activity_desc TEXT;
  activity_type_val VARCHAR(50);
  photo_before INTEGER;
  photo_after INTEGER;
BEGIN
  IF TG_OP = 'INSERT' THEN
    activity_type_val := 'milestone_progress_updated';
    activity_desc := format('Milestone "%s" dibuat dengan target %s foto', NEW.name, NEW.photo_needed);
    photo_before := 0;
    photo_after := NEW.photos_uploaded;
    
    INSERT INTO public.project_activities_log (
      project_id, activity_type, activity_description, milestone_id, milestone_name,
      photo_count_before, photo_count_after, user_id
    ) VALUES (
      NEW.project_id, activity_type_val, activity_desc, NEW.id, NEW.name,
      photo_before, photo_after, auth.uid()
    );
    
    RETURN NEW;
    
  ELSIF TG_OP = 'UPDATE' THEN
    photo_before := OLD.photos_uploaded;
    photo_after := NEW.photos_uploaded;
    
    -- Only log if photos_uploaded changed
    IF photo_before != photo_after THEN
      IF photo_after > photo_before THEN
        activity_type_val := 'milestone_photo_added';
        activity_desc := format('Milestone "%s" +%s foto ditambahkan (%s/%s)', 
          NEW.name, (photo_after - photo_before), photo_after, NEW.photo_needed);
      ELSIF photo_after < photo_before THEN
        activity_type_val := 'milestone_photo_deleted';
        activity_desc := format('Milestone "%s" -%s foto dihapus (%s/%s)', 
          NEW.name, (photo_before - photo_after), photo_after, NEW.photo_needed);
      END IF;
      
      -- Check if milestone is completed
      IF NEW.photos_uploaded >= NEW.photo_needed AND OLD.photos_uploaded < OLD.photo_needed THEN
        activity_type_val := 'milestone_completed';
        activity_desc := format('Milestone "%s" telah selesai (%s/%s foto)', 
          NEW.name, NEW.photos_uploaded, NEW.photo_needed);
      END IF;
      
      INSERT INTO public.project_activities_log (
        project_id, activity_type, activity_description, milestone_id, milestone_name,
        photo_count_before, photo_count_after, user_id
      ) VALUES (
        NEW.project_id, activity_type_val, activity_desc, NEW.id, NEW.name,
        photo_before, photo_after, auth.uid()
      );
    END IF;
    
    RETURN NEW;
    
  ELSIF TG_OP = 'DELETE' THEN
    activity_type_val := 'milestone_progress_updated';
    activity_desc := format('Milestone "%s" dihapus', OLD.name);
    
    INSERT INTO public.project_activities_log (
      project_id, activity_type, activity_description, milestone_id, milestone_name,
      photo_count_before, photo_count_after, user_id
    ) VALUES (
      OLD.project_id, activity_type_val, activity_desc, OLD.id, OLD.name,
      OLD.photos_uploaded, 0, auth.uid()
    );
    
    RETURN OLD;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Function to log implementation activities
CREATE OR REPLACE FUNCTION log_implementation_activity()
RETURNS TRIGGER AS $$
DECLARE
  activity_desc TEXT;
  activity_type_val VARCHAR(50);
  item_title_val TEXT;
  project_id_val INTEGER;
BEGIN
  -- Get item title and project_id through the relationship chain
  SELECT ri.item_title, ri.project_id INTO item_title_val, project_id_val
  FROM public.report_items ri
  WHERE ri.id = COALESCE(NEW.report_item_id, OLD.report_item_id);
  
  IF TG_OP = 'INSERT' THEN
    activity_type_val := 'report_implementation_added';
    activity_desc := format('Progress "%s" ditambahkan: %s unit pada %s', 
      item_title_val, NEW.daily_quantity, NEW.implementation_date);
    
    INSERT INTO public.project_activities_log (
      project_id, activity_type, activity_description, report_item_id,
      implementation_date, daily_quantity, item_title, user_id
    ) VALUES (
      project_id_val, activity_type_val, activity_desc, NEW.report_item_id,
      NEW.implementation_date, NEW.daily_quantity, item_title_val, auth.uid()
    );
    
    RETURN NEW;
    
  ELSIF TG_OP = 'UPDATE' THEN
    activity_type_val := 'report_implementation_updated';
    activity_desc := format('Progress "%s" diperbarui: %s unit pada %s', 
      item_title_val, NEW.daily_quantity, NEW.implementation_date);
    
    INSERT INTO public.project_activities_log (
      project_id, activity_type, activity_description, report_item_id,
      implementation_date, daily_quantity, item_title, user_id
    ) VALUES (
      project_id_val, activity_type_val, activity_desc, NEW.report_item_id,
      NEW.implementation_date, NEW.daily_quantity, item_title_val, auth.uid()
    );
    
    RETURN NEW;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- ============================================================================
-- CREATE TRIGGERS
-- ============================================================================

CREATE TRIGGER milestone_activity_log_trigger
  AFTER INSERT OR UPDATE OR DELETE ON milestones
  FOR EACH ROW EXECUTE FUNCTION log_milestone_activity();

CREATE TRIGGER implementation_activity_log_trigger
  AFTER INSERT OR UPDATE ON report_implementations
  FOR EACH ROW EXECUTE FUNCTION log_implementation_activity();

-- ============================================================================
-- VIEWS FOR EASY ACCESS
-- ============================================================================

-- View for recent project activities
CREATE OR REPLACE VIEW recent_project_activities
WITH (security_invoker=on) AS
SELECT 
  pal.id,
  pal.project_id,
  p.name as project_name,
  p.location as project_location,
  pal.activity_type,
  pal.activity_description,
  pal.milestone_id,
  pal.milestone_name,
  pal.report_item_id,
  pal.storage_path,
  pal.photo_count_before,
  pal.photo_count_after,
  pal.implementation_date,
  pal.daily_quantity,
  pal.item_title,
  pal.user_id,
  pal.created_at,
  -- Calculate relative time
  CASE 
    WHEN pal.created_at > NOW() - INTERVAL '1 minute' THEN 'baru saja'
    WHEN pal.created_at > NOW() - INTERVAL '1 hour' THEN 
      EXTRACT(EPOCH FROM (NOW() - pal.created_at))::INTEGER / 60 || ' menit yang lalu'
    WHEN pal.created_at > NOW() - INTERVAL '1 day' THEN 
      EXTRACT(EPOCH FROM (NOW() - pal.created_at))::INTEGER / 3600 || ' jam yang lalu'
    WHEN pal.created_at > NOW() - INTERVAL '7 days' THEN 
      EXTRACT(EPOCH FROM (NOW() - pal.created_at))::INTEGER / 86400 || ' hari yang lalu'
    ELSE TO_CHAR(pal.created_at, 'DD Mon YYYY')
  END as relative_time
FROM project_activities_log pal
JOIN projects p ON pal.project_id = p.id
ORDER BY pal.created_at DESC;

-- View for today activities summary
CREATE OR REPLACE VIEW today_activities_summary
WITH (security_invoker=on) AS
SELECT 
  p.id as project_id,
  p.name as project_name,
  p.location,
  0 as daily_reports_count,
  0 as total_work_hours,
  false as has_report_changes,
  COALESCE(SUM(m.photos_uploaded), 0) as total_photos_uploaded,
  CASE 
    WHEN COUNT(m.id) > 0 THEN 
      ROUND(AVG(CASE WHEN m.photo_needed > 0 THEN (m.photos_uploaded::DECIMAL / m.photo_needed) * 100 ELSE 0 END), 2)
    ELSE 0
  END as milestone_completion_avg,
  NULL as activities_summary,
  NULL as plans_summary,
  NULL as issues_summary,
  false as has_issues,
  NOW()::TEXT as updated_at
FROM projects p
LEFT JOIN milestones m ON p.id = m.project_id
GROUP BY p.id, p.name, p.location;

-- View for daily activities list
CREATE OR REPLACE VIEW daily_activities_list
WITH (security_invoker=on) AS
SELECT 
  p.id,
  p.id as project_id,
  CURRENT_DATE::TEXT as activity_date,
  0 as milestones_updated,
  COALESCE(SUM(m.photos_uploaded), 0) as total_photos_uploaded,
  COALESCE(SUM(m.photo_needed), 0) as total_photos_needed,
  CASE 
    WHEN COUNT(m.id) > 0 THEN 
      ROUND(AVG(CASE WHEN m.photo_needed > 0 THEN (m.photos_uploaded::DECIMAL / m.photo_needed) * 100 ELSE 0 END), 2)
    ELSE 0
  END as milestone_completion_avg,
  0 as daily_reports_count,
  0 as total_work_hours,
  0 as progress_x_total,
  0 as progress_y_total,
  0 as progress_z_total,
  NULL as activities_summary,
  NULL as plans_summary,
  NULL as issues_summary,
  false as has_milestone_changes,
  false as has_report_changes,
  false as has_issues,
  NOW()::TEXT as created_at,
  NOW()::TEXT as updated_at,
  p.name as project_name,
  p.location as project_location
FROM projects p
LEFT JOIN milestones m ON p.id = m.project_id
GROUP BY p.id, p.name, p.location;

-- Add security barriers to views
ALTER VIEW recent_project_activities SET (security_barrier = true);
ALTER VIEW today_activities_summary SET (security_barrier = true);
ALTER VIEW daily_activities_list SET (security_barrier = true);

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

ALTER TABLE project_activities_log ENABLE ROW LEVEL SECURITY;

-- Consolidated policy for project_activities_log
CREATE POLICY "Project activities log access policy" ON project_activities_log
  FOR ALL
  USING (
    public.current_user_is_admin()
    OR public.user_has_project_access(project_activities_log.project_id)
  );

-- ============================================================================
-- REAL-TIME OPTIMIZATION FUNCTIONS
-- ============================================================================

-- Function to notify real-time activity updates
CREATE OR REPLACE FUNCTION notify_activity_update()
RETURNS TRIGGER AS $$
BEGIN
  -- Only send notifications for INSERT operations to prevent duplicates
  IF TG_OP = 'INSERT' THEN
    -- Add a small delay to prevent rapid duplicate notifications
    PERFORM pg_sleep(0.1);
    
    -- Send real-time notification for new activities
    PERFORM pg_notify(
      'activity_updates',
      json_build_object(
        'project_id', NEW.project_id,
        'activity_id', NEW.id,
        'activity_type', NEW.activity_type,
        'operation', TG_OP,
        'timestamp', EXTRACT(EPOCH FROM NEW.created_at)
      )::text
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Create trigger for real-time notifications
CREATE TRIGGER activity_realtime_trigger
  AFTER INSERT OR UPDATE ON project_activities_log
  FOR EACH ROW EXECUTE FUNCTION notify_activity_update();

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Function to get recent activities for a project with pagination (optimized)
CREATE OR REPLACE FUNCTION get_project_recent_activities_paginated(
  target_project_id INTEGER,
  limit_count INTEGER DEFAULT 20,
  offset_count INTEGER DEFAULT 0
)
RETURNS TABLE (
  id INTEGER,
  activity_type VARCHAR(50),
  activity_description TEXT,
  milestone_id INTEGER,
  milestone_name VARCHAR(255),
  report_item_id INTEGER,
  storage_path TEXT,
  photo_count_before INTEGER,
  photo_count_after INTEGER,
  implementation_date DATE,
  daily_quantity DECIMAL(10,2),
  item_title TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  relative_time TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    rpa.id,
    rpa.activity_type,
    rpa.activity_description,
    rpa.milestone_id,
    rpa.milestone_name,
    rpa.report_item_id,
    rpa.storage_path,
    rpa.photo_count_before,
    rpa.photo_count_after,
    rpa.implementation_date,
    rpa.daily_quantity,
    rpa.item_title,
    rpa.created_at,
    rpa.relative_time
  FROM public.recent_project_activities rpa
  WHERE rpa.project_id = target_project_id
  ORDER BY rpa.created_at DESC
  LIMIT limit_count
  OFFSET offset_count;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Function to calculate project progress on backend
CREATE OR REPLACE FUNCTION calculate_project_progress(target_project_id INTEGER)
RETURNS TABLE (
  project_id INTEGER,
  total_milestones INTEGER,
  completed_milestones INTEGER,
  in_progress_milestones INTEGER,
  milestone_progress DECIMAL(5,2),
  total_reports INTEGER,
  report_progress DECIMAL(5,2),
  combined_progress DECIMAL(5,2),
  total_photos INTEGER,
  required_photos INTEGER,
  photo_progress DECIMAL(5,2)
) AS $$
DECLARE
  milestone_stats RECORD;
  report_stats RECORD;
  photo_stats RECORD;
BEGIN
  -- Calculate milestone statistics
  SELECT 
    COUNT(*) as total,
    COUNT(CASE WHEN photos_uploaded >= photo_needed THEN 1 END) as completed,
    COUNT(CASE WHEN photos_uploaded > 0 AND photos_uploaded < photo_needed THEN 1 END) as in_progress
  INTO milestone_stats
  FROM public.milestones 
  WHERE project_id = target_project_id;

  -- Calculate report statistics (updated for new schema)
  SELECT 
    COUNT(DISTINCT ri.implementation_date) as total
  INTO report_stats
  FROM public.report_implementations ri
  LEFT JOIN public.report_items rep_items ON ri.report_item_id = rep_items.id
  LEFT JOIN public.report_parent_items rpi ON rep_items.parent_item_id = rpi.id
  WHERE rpi.project_id = target_project_id;

  -- Calculate photo statistics
  SELECT 
    COALESCE(SUM(photos_uploaded), 0) as uploaded,
    COALESCE(SUM(photo_needed), 0) as needed
  INTO photo_stats
  FROM public.milestones 
  WHERE project_id = target_project_id;

  RETURN QUERY
  SELECT 
    target_project_id,
    milestone_stats.total,
    milestone_stats.completed,
    milestone_stats.in_progress,
    CASE 
      WHEN milestone_stats.total > 0 THEN 
        ROUND((milestone_stats.completed::DECIMAL / milestone_stats.total) * 100, 2)
      ELSE 0::DECIMAL(5,2)
    END,
    report_stats.total,
    CASE 
      WHEN report_stats.total > 0 THEN 
        100::DECIMAL(5,2) -- All reports are considered complete in new schema
      ELSE 0::DECIMAL(5,2)
    END,
    CASE 
      WHEN milestone_stats.total > 0 AND report_stats.total > 0 THEN 
        ROUND((
          (milestone_stats.completed::DECIMAL / milestone_stats.total * 0.7) +
          (1.0 * 0.3) -- All reports are considered complete
        ) * 100, 2)
      WHEN milestone_stats.total > 0 THEN 
        ROUND((milestone_stats.completed::DECIMAL / milestone_stats.total) * 100, 2)
      WHEN report_stats.total > 0 THEN 
        100::DECIMAL(5,2) -- All reports are considered complete
      ELSE 0::DECIMAL(5,2)
    END,
    photo_stats.uploaded,
    photo_stats.needed,
    CASE 
      WHEN photo_stats.needed > 0 THEN 
        ROUND((photo_stats.uploaded::DECIMAL / photo_stats.needed) * 100, 2)
      ELSE 0::DECIMAL(5,2)
    END;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Function to get activity stats
CREATE OR REPLACE FUNCTION get_activity_stats(
  target_project_id INTEGER,
  days_back INTEGER DEFAULT 30
)
RETURNS TABLE (
  total_days INTEGER,
  avg_work_hours DECIMAL(10,2),
  avg_completion DECIMAL(5,2),
  total_reports INTEGER,
  days_with_issues INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    days_back as total_days,
    0::DECIMAL(10,2) as avg_work_hours,
    CASE 
      WHEN COUNT(m.id) > 0 THEN 
        ROUND(AVG(CASE WHEN m.photo_needed > 0 THEN (m.photos_uploaded::DECIMAL / m.photo_needed) * 100 ELSE 0 END), 2)
      ELSE 0::DECIMAL(5,2)
    END as avg_completion,
    COUNT(DISTINCT ri.implementation_date)::INTEGER as total_reports,
    0 as days_with_issues
  FROM public.projects p
  LEFT JOIN public.milestones m ON p.id = m.project_id
  LEFT JOIN public.report_items rep_items ON rep_items.parent_item_id IN (
    SELECT id FROM public.report_parent_items WHERE project_id = target_project_id
  )
  LEFT JOIN public.report_implementations ri ON ri.report_item_id = rep_items.id
    AND ri.implementation_date >= CURRENT_DATE - (days_back || ' days')::INTERVAL
  WHERE p.id = target_project_id
  GROUP BY p.id;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Function to cleanup old activity logs (optional, for maintenance)
CREATE OR REPLACE FUNCTION cleanup_old_activity_logs(
  days_to_keep INTEGER DEFAULT 90
)
RETURNS TEXT AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM public.project_activities_log 
  WHERE created_at < NOW() - (days_to_keep || ' days')::INTERVAL;
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  
  RETURN format('Deleted %s old activity log records', deleted_count);
END;
$$ LANGUAGE plpgsql SET search_path = '';