-- Create files table
CREATE TABLE public.files (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    file_name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.files ENABLE ROW LEVEL SECURITY;

-- Create an index on user_id for better performance
CREATE INDEX idx_files_user_id ON public.files(user_id);

-- Add RLS policy for files table
CREATE POLICY "Files access policy" ON public.files
  FOR ALL
  USING (
    public.current_user_is_admin()
    OR user_id = public.current_user_id()
  );

-- Create bucket and set up policies for milestone photos
-- NOTE: After R2 migration, this storage bucket and policies are no longer used.
-- Kept for backward compatibility during transition.
DO $$
BEGIN
    -- Ensure storage bucket exists (force creation)
    INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
    VALUES ('milestone-photos', 'milestone-photos', true, 52428800, ARRAY['image/jpeg', 'image/png', 'image/webp'])
    ON CONFLICT (id) DO UPDATE SET 
        public = true,
        file_size_limit = 52428800,
        allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

    -- Drop existing policies first
    DROP POLICY IF EXISTS "Authenticated users can view milestone photos" ON storage.objects;
    DROP POLICY IF EXISTS "Authenticated users can upload milestone photos" ON storage.objects;
    DROP POLICY IF EXISTS "Authenticated users can delete their own milestone photos" ON storage.objects;
    
    -- Set up more permissive storage policies
    CREATE POLICY "Anyone can view milestone photos"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'milestone-photos');

    CREATE POLICY "Authenticated users can upload milestone photos"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (bucket_id = 'milestone-photos');

    CREATE POLICY "Authenticated users can update milestone photos"
    ON storage.objects FOR UPDATE
    TO authenticated
    USING (bucket_id = 'milestone-photos');

    CREATE POLICY "Authenticated users can delete milestone photos"
    ON storage.objects FOR DELETE
    TO authenticated
    USING (bucket_id = 'milestone-photos');
EXCEPTION 
    WHEN OTHERS THEN 
        NULL;
END $$;

-- Add trigger function to auto-update photos_uploaded
CREATE OR REPLACE FUNCTION update_milestone_photos_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.milestones 
  SET photos_uploaded = (
    SELECT COUNT(*) 
    FROM public.milestone_photos 
    WHERE milestone_id = COALESCE(NEW.milestone_id, OLD.milestone_id)
  )
  WHERE id = COALESCE(NEW.milestone_id, OLD.milestone_id);
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Create triggers for INSERT and DELETE operations
CREATE TRIGGER trigger_update_photos_count_insert
  AFTER INSERT ON milestone_photos
  FOR EACH ROW
  EXECUTE FUNCTION update_milestone_photos_count();

CREATE TRIGGER trigger_update_photos_count_delete
  AFTER DELETE ON milestone_photos
  FOR EACH ROW
  EXECUTE FUNCTION update_milestone_photos_count();

-- Add policies for milestone_photos table (remove duplicate)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'milestone_photos') THEN
        -- Note: The main policy is created in 09_create_milestone_photos_table.sql
        -- This DO block is left for potential future storage-specific policies
        NULL; -- Placeholder
    END IF;
END $$;


-- Add trigger function to auto-update photos_uploaded from storage
CREATE OR REPLACE FUNCTION update_milestone_photos_count_from_storage()
RETURNS TRIGGER AS $$
DECLARE
    milestone_id_from_path BIGINT;
    project_id_from_path BIGINT;
    photo_count INTEGER;
BEGIN
    -- Extract milestone_id from storage object path
    -- Path format: project-{project_id}/milestone-{milestone_id}/filename
    IF TG_OP = 'INSERT' THEN
        -- Extract project_id and milestone_id from path like "project-2/milestone-34/filename.jpg"
        project_id_from_path := CAST(split_part(split_part(NEW.name, '/', 1), '-', 2) AS BIGINT);
        milestone_id_from_path := CAST(split_part(split_part(NEW.name, '/', 2), '-', 2) AS BIGINT);
    ELSIF TG_OP = 'DELETE' THEN
        project_id_from_path := CAST(split_part(split_part(OLD.name, '/', 1), '-', 2) AS BIGINT);
        milestone_id_from_path := CAST(split_part(split_part(OLD.name, '/', 2), '-', 2) AS BIGINT);
    END IF;
    
    -- Count photos in storage for this milestone
    SELECT COUNT(*) INTO photo_count
    FROM storage.objects 
    WHERE bucket_id = 'milestone-photos' 
    AND name LIKE 'project-' || project_id_from_path || '/milestone-' || milestone_id_from_path || '/%';
    
    -- Update milestone photos_uploaded count
    UPDATE public.milestones 
    SET photos_uploaded = photo_count
    WHERE id = milestone_id_from_path;
    
    RETURN COALESCE(NEW, OLD);
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail the storage operation
        RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Create triggers for storage operations
DROP TRIGGER IF EXISTS trigger_update_photos_count_storage_insert ON storage.objects;
CREATE TRIGGER trigger_update_photos_count_storage_insert
  AFTER INSERT ON storage.objects
  FOR EACH ROW
  WHEN (NEW.bucket_id = 'milestone-photos')
  EXECUTE FUNCTION update_milestone_photos_count_from_storage();

DROP TRIGGER IF EXISTS trigger_update_photos_count_storage_delete ON storage.objects;
CREATE TRIGGER trigger_update_photos_count_storage_delete
  AFTER DELETE ON storage.objects
  FOR EACH ROW
  WHEN (OLD.bucket_id = 'milestone-photos')
  EXECUTE FUNCTION update_milestone_photos_count_from_storage();
