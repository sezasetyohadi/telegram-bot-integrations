-- Cleanup obsolete Supabase Storage configurations after R2 migration
-- This migration removes storage-related configurations that are no longer needed

-- Drop storage triggers that are no longer used
DROP TRIGGER IF EXISTS trigger_update_photos_count_storage_insert ON storage.objects;
DROP TRIGGER IF EXISTS trigger_update_photos_count_storage_delete ON storage.objects;

-- Drop storage-related function
DROP FUNCTION IF EXISTS update_milestone_photos_count_from_storage();

-- Remove storage policies (commented out to prevent accidental deletion)
-- DROP POLICY IF EXISTS "Anyone can view milestone photos" ON storage.objects;
-- DROP POLICY IF EXISTS "Authenticated users can upload milestone photos" ON storage.objects;
-- DROP POLICY IF EXISTS "Authenticated users can update milestone photos" ON storage.objects;
-- DROP POLICY IF EXISTS "Authenticated users can delete milestone photos" ON storage.objects;

-- Note: We keep the milestone-photos bucket for backward compatibility
-- but it's no longer actively used since we moved to R2

-- Add comment to milestone_photos table to clarify R2 usage
COMMENT ON TABLE public.milestone_photos IS 'Milestone photos metadata. Photos are stored in Cloudflare R2, URLs stored in url column.';
COMMENT ON COLUMN public.milestone_photos.url IS 'Permanent R2 URL for the photo. Replaces Supabase Storage path completely.';
