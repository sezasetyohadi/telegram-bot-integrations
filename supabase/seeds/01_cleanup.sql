-- Seed file for cleaning up existing data

-- Clean up ALL storage buckets and files first
DO $$
DECLARE
    bucket_record RECORD;
    protected_buckets TEXT[] := ARRAY['milestone-photos', 'logo-templates']; -- Protect important buckets
BEGIN
    -- Delete all objects from buckets except protected ones
    FOR bucket_record IN 
        SELECT id FROM storage.buckets 
        WHERE id != ALL(protected_buckets) 
    LOOP
        DELETE FROM storage.objects WHERE bucket_id = bucket_record.id;
    END LOOP;
    
    -- Delete only objects from protected buckets, but keep the buckets themselves
    DELETE FROM storage.objects 
    WHERE bucket_id = ANY(protected_buckets);
    
    -- Delete all buckets except protected ones
    DELETE FROM storage.buckets 
    WHERE id != ALL(protected_buckets);
    
    -- Clean up any orphaned files table records
    DELETE FROM public.files;
    
    -- Clean up milestone_photos table if it exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'milestone_photos') THEN
        DELETE FROM milestone_photos;
    END IF;
    
    -- Clean up logo_templates table if it exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'logo_templates') THEN
        DELETE FROM logo_templates;
    END IF;
    
EXCEPTION 
    WHEN others THEN 
        RAISE NOTICE 'Storage cleanup error: %', SQLERRM;
        -- Continue even if storage cleanup fails
        NULL;
END $$;

-- Temporarily disable triggers that enforce role-based constraints
DO $$
BEGIN
    -- Disable triggers if they exist
    IF EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'enforce_project_assignment_roles') THEN
        ALTER TABLE project_assignments DISABLE TRIGGER enforce_project_assignment_roles;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'prevent_unassigned_projects') THEN
        ALTER TABLE project_assignments DISABLE TRIGGER prevent_unassigned_projects;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.triggers WHERE trigger_name = 'ensure_project_has_assignment') THEN
        ALTER TABLE projects DISABLE TRIGGER ensure_project_has_assignment;
    END IF;
EXCEPTION 
    WHEN others THEN 
        RAISE NOTICE 'Trigger disable error: %', SQLERRM;
        NULL;
END $$;

-- Hapus data yang ada (opsional, hapus jika tidak ingin menghapus data)
DO $$
BEGIN
    -- Truncate NEW reporting system tables
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'report_implementations') THEN
        TRUNCATE TABLE report_implementations CASCADE;
        RAISE NOTICE 'Truncated report_implementations table';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'report_items') THEN
        TRUNCATE TABLE report_items CASCADE;
        RAISE NOTICE 'Truncated report_items table';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'report_template_items') THEN
        TRUNCATE TABLE report_template_items CASCADE;
        RAISE NOTICE 'Truncated report_template_items table';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'report_templates') THEN
        TRUNCATE TABLE report_templates CASCADE;
        RAISE NOTICE 'Truncated report_templates table';
    END IF;
    
    -- Truncate additional reporting tables
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'report_issues') THEN
        TRUNCATE TABLE report_issues CASCADE;
        RAISE NOTICE 'Truncated report_issues table';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'report_tomorrow_plans') THEN
        TRUNCATE TABLE report_tomorrow_plans CASCADE;
        RAISE NOTICE 'Truncated report_tomorrow_plans table';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'report_atp_civil_work') THEN
        TRUNCATE TABLE report_atp_civil_work CASCADE;
        RAISE NOTICE 'Truncated report_atp_civil_work table';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'report_atp_opm_test') THEN
        TRUNCATE TABLE report_atp_opm_test CASCADE;
        RAISE NOTICE 'Truncated report_atp_opm_test table';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'report_work_time') THEN
        TRUNCATE TABLE report_work_time CASCADE;
        RAISE NOTICE 'Truncated report_work_time table';
    END IF;
    
    -- Truncate existing tables
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'project_assignments') THEN
        TRUNCATE TABLE project_assignments CASCADE;
        RAISE NOTICE 'Truncated project_assignments table';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'project_activities_log') THEN
        TRUNCATE TABLE project_activities_log CASCADE;
        RAISE NOTICE 'Truncated project_activities_log table';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'milestones') THEN
        TRUNCATE TABLE milestones CASCADE;
        RAISE NOTICE 'Truncated milestones table';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'projects') THEN
        TRUNCATE TABLE projects CASCADE;
        RAISE NOTICE 'Truncated projects table';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_roles') THEN
        TRUNCATE TABLE user_roles CASCADE;
        RAISE NOTICE 'Truncated user_roles table';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'milestone_photos') THEN
        TRUNCATE TABLE milestone_photos CASCADE;
        RAISE NOTICE 'Truncated milestone_photos table';
    END IF;
    
    -- Truncate logo templates table if it exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'logo_templates') THEN
        TRUNCATE TABLE logo_templates CASCADE;
        RAISE NOTICE 'Truncated logo_templates table';
    END IF;
    
EXCEPTION 
    WHEN others THEN 
        RAISE NOTICE 'Table truncation error: %', SQLERRM;
        NULL;
END $$;

-- Final verification
DO $$
DECLARE
    bucket_count INTEGER;
    protected_buckets TEXT[] := ARRAY['milestone-photos', 'logo-templates'];
    bucket_name TEXT;
BEGIN
    RAISE NOTICE '=== CLEANUP VERIFICATION ===';
    
    -- Check protected buckets
    FOREACH bucket_name IN ARRAY protected_buckets LOOP
        SELECT COUNT(*) INTO bucket_count FROM storage.buckets WHERE id = bucket_name;
        IF bucket_count > 0 THEN
            RAISE NOTICE 'SUCCESS: % bucket preserved', bucket_name;
        ELSE
            RAISE NOTICE 'WARNING: % bucket not found', bucket_name;
        END IF;
    END LOOP;
    
    RAISE NOTICE '=== CLEANUP COMPLETED ===';
END $$;