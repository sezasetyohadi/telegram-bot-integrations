-- Seed file untuk categories global
DO $$
DECLARE
  category_id INTEGER;
  project_record RECORD;
  category_names TEXT[] := ARRAY['IMPLEMENTASI', 'INSTALL FDT', 'INSTALL FAT', 'ELECTRICAL'];
BEGIN
  -- Insert kategori global (hanya sekali)
  FOR i IN 1..array_length(category_names, 1) LOOP
    INSERT INTO categories (name)
    VALUES (category_names[i])
    RETURNING id INTO category_id;
    
    -- Hubungkan kategori dengan semua proyek yang ada
    FOR project_record IN SELECT id FROM projects LOOP
      INSERT INTO project_categories (project_id, category_id)
      VALUES (project_record.id, category_id);
    END LOOP;
  END LOOP;
END $$;