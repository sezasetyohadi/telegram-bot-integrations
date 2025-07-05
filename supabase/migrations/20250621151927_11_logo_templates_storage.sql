-- Step 1: Create logo-templates bucket with better error handling
DO $$
DECLARE
    bucket_exists BOOLEAN := FALSE;
BEGIN
    -- Check if bucket already exists
    SELECT EXISTS(SELECT 1 FROM storage.buckets WHERE id = 'logo-templates') INTO bucket_exists;
    
    IF NOT bucket_exists THEN
        -- Create the bucket
        INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
        VALUES ('logo-templates', 'logo-templates', false, 52428800, ARRAY['image/jpeg', 'image/png', 'image/webp']);
        
        RAISE NOTICE 'Successfully created logo-templates bucket';
    ELSE
        -- Update existing bucket
        UPDATE storage.buckets 
        SET public = false,
            file_size_limit = 52428800,
            allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp']
        WHERE id = 'logo-templates';
        
        RAISE NOTICE 'Updated existing logo-templates bucket';
    END IF;
    
EXCEPTION 
    WHEN OTHERS THEN 
        RAISE NOTICE 'Error creating/updating logo-templates bucket: %', SQLERRM;
        -- Don't hide the error, let it propagate
        RAISE;
END $$;

-- Step 2: Create table for logo template metadata
CREATE TABLE IF NOT EXISTS public.logo_templates (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    canvas_width INTEGER NOT NULL DEFAULT 400,
    canvas_height INTEGER NOT NULL DEFAULT 300,
    created_by TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Step 3: Add indexes for better performance (optimized)
-- Keep only essential indexes
CREATE INDEX IF NOT EXISTS idx_logo_templates_name ON logo_templates(name);
-- Remove created_at index as it's rarely queried
-- DROP INDEX IF EXISTS idx_logo_templates_created_at;

-- Step 4: Enable RLS
ALTER TABLE public.logo_templates ENABLE ROW LEVEL SECURITY;

-- Step 5: Create storage policies with better error handling
DO $$
DECLARE
    policy_names TEXT[] := ARRAY[
        'Authenticated users can view logo templates',
        'Authenticated users can upload logo templates', 
        'Authenticated users can update logo templates',
        'Authenticated users can delete logo templates'
    ];
    policy_name TEXT;
BEGIN
    -- Drop existing policies first
    FOREACH policy_name IN ARRAY policy_names LOOP
        BEGIN
            EXECUTE format('DROP POLICY IF EXISTS "%s" ON storage.objects', policy_name);
            RAISE NOTICE 'Dropped policy: %', policy_name;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Could not drop policy %: %', policy_name, SQLERRM;
        END;
    END LOOP;
    
    -- Create new policies
    CREATE POLICY "Authenticated users can view logo templates"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (bucket_id = 'logo-templates');
    RAISE NOTICE 'Created SELECT policy for logo-templates';

    CREATE POLICY "Authenticated users can upload logo templates"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'logo-templates');
    RAISE NOTICE 'Created INSERT policy for logo-templates';

    CREATE POLICY "Authenticated users can update logo templates"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (bucket_id = 'logo-templates');
    RAISE NOTICE 'Created UPDATE policy for logo-templates';

    CREATE POLICY "Authenticated users can delete logo templates"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (bucket_id = 'logo-templates');
    RAISE NOTICE 'Created DELETE policy for logo-templates';
    
EXCEPTION 
    WHEN OTHERS THEN 
        RAISE NOTICE 'Error creating storage policies: %', SQLERRM;
        RAISE;
END $$;

-- Step 6: Create RLS policies for the table (optimized)
DO $$
BEGIN
    -- Drop existing table policies
    DROP POLICY IF EXISTS "Allow authenticated users to view logo templates" ON public.logo_templates;
    DROP POLICY IF EXISTS "Allow authenticated users to insert logo templates" ON public.logo_templates;
    DROP POLICY IF EXISTS "Allow authenticated users to update logo_templates" ON public.logo_templates;
    DROP POLICY IF EXISTS "Allow authenticated users to delete logo templates" ON public.logo_templates;
    
    -- Create consolidated policy for logo_templates
    CREATE POLICY "Logo templates access policy" ON public.logo_templates
        FOR ALL TO authenticated USING (
            public.current_user_is_any_admin() 
            OR public.current_user_role() = 'authenticated'
        );
        
    RAISE NOTICE 'Successfully created consolidated RLS policy for logo_templates table';
    
EXCEPTION 
    WHEN OTHERS THEN 
        RAISE NOTICE 'Error creating table policies: %', SQLERRM;
        RAISE;
END $$;

-- Step 7: Verify bucket creation
DO $$
DECLARE
    bucket_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO bucket_count FROM storage.buckets WHERE id = 'logo-templates';
    
    IF bucket_count > 0 THEN
        RAISE NOTICE 'SUCCESS: logo-templates bucket exists and is ready to use';
    ELSE
        RAISE NOTICE 'ERROR: logo-templates bucket was not created';
    END IF;
END $$;