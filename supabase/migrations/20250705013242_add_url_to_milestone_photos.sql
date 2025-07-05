-- Add url column to milestone_photos table for R2 storage URLs
-- This migration adds the url column to store permanent R2 URLs

-- Add the url column to milestone_photos table
ALTER TABLE public.milestone_photos 
ADD COLUMN url TEXT;

-- Add an index on the url column for better performance
CREATE INDEX idx_milestone_photos_url ON public.milestone_photos(url);

-- Add a comment to document the purpose
COMMENT ON COLUMN public.milestone_photos.url IS 'Permanent R2 URL for the photo. Replaces Supabase Storage path.';
