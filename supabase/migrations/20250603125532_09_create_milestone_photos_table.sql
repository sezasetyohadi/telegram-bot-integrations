-- Membuat tipe enum untuk status persetujuan
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'status_approval_enum') THEN
    CREATE TYPE public.status_approval_enum AS ENUM ('approved', 'rejected', 'pending');
  END IF;
END $$;


-- Membuat tabel milestone_photos dengan tipe data foreign key yang benar
CREATE TABLE IF NOT EXISTS public.milestone_photos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  milestone_id INTEGER NOT NULL REFERENCES public.milestones(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  approval_status public.status_approval_enum NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
  UNIQUE(milestone_id, name)
);

-- Membuat fungsi untuk memperbarui kolom updated_at
CREATE OR REPLACE FUNCTION public.update_milestone_photos_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = '';

-- Membuat trigger untuk menjalankan fungsi di atas secara otomatis
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgname = 'trigger_update_milestone_photos_updated_at' AND tgrelid = 'public.milestone_photos'::regclass
  ) THEN
    CREATE TRIGGER trigger_update_milestone_photos_updated_at
    BEFORE UPDATE ON public.milestone_photos
    FOR EACH ROW
    EXECUTE FUNCTION public.update_milestone_photos_updated_at();
  END IF;
END $$;

-- OPTIMIZATION: Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_milestone_photos_milestone_id ON public.milestone_photos(milestone_id);
CREATE INDEX IF NOT EXISTS idx_milestone_photos_approval_status ON public.milestone_photos(approval_status);
CREATE INDEX IF NOT EXISTS idx_milestone_photos_created_at ON public.milestone_photos(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_milestone_photos_milestone_approval ON public.milestone_photos(milestone_id, approval_status);
CREATE INDEX IF NOT EXISTS idx_milestone_photos_status_date ON public.milestone_photos(milestone_id, approval_status, created_at);

-- Mengaktifkan Row Level Security (RLS)
ALTER TABLE public.milestone_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.milestone_photos FORCE ROW LEVEL SECURITY;

-- Performance optimized function for milestone photo access
CREATE OR REPLACE FUNCTION public.user_has_milestone_access(milestone_id INTEGER)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.milestones m
    JOIN public.project_assignments pa ON m.project_id = pa.project_id
    WHERE m.id = $1 AND pa.assigned_to = public.current_user_id()
  );
$$;

-- Single consolidated policy for milestone_photos
CREATE POLICY "Milestone photos unified access policy" ON public.milestone_photos
  FOR ALL
  USING (
    public.current_user_is_any_admin()
    OR public.user_has_milestone_access(milestone_photos.milestone_id)
  );