-- Generate milestones untuk setiap category berdasarkan template
DO $$
DECLARE
  implementasi_id INTEGER;
  install_fdt_id INTEGER;
  install_fat_id INTEGER;
  electrical_id INTEGER;
  project_record RECORD;
  milestone_id INTEGER;
BEGIN
  -- Ambil ID kategori global
  SELECT id INTO implementasi_id FROM categories WHERE name = 'IMPLEMENTASI' LIMIT 1;
  SELECT id INTO install_fdt_id FROM categories WHERE name = 'INSTALL FDT' LIMIT 1;
  SELECT id INTO install_fat_id FROM categories WHERE name = 'INSTALL FAT' LIMIT 1;
  SELECT id INTO electrical_id FROM categories WHERE name = 'ELECTRICAL' LIMIT 1;
  
  -- Loop melalui semua project
  FOR project_record IN SELECT id, name, location FROM projects LOOP
    -- IMPLEMENTASI milestones
    INSERT INTO milestones (name, project, project_id, category_id, photo_needed, photos_uploaded)
    VALUES ('Foto Digging Pole (Menggali Lubang Untuk tanam Pole)', project_record.name, project_record.id, implementasi_id, 6, 4);
    
    INSERT INTO milestones (name, project, project_id, category_id, photo_needed, photos_uploaded)
    VALUES ('Foto Mengukur Kedalaman Lubang galian', project_record.name, project_record.id, implementasi_id, 6, 4);
    
    INSERT INTO milestones (name, project, project_id, category_id, photo_needed, photos_uploaded)
    VALUES ('Foto Prepare Install Pole', project_record.name, project_record.id, implementasi_id, 6, 4);
    
    INSERT INTO milestones (name, project, project_id, category_id, photo_needed, photos_uploaded)
    VALUES ('Foto Install Pole', project_record.name, project_record.id, implementasi_id, 6, 4);
    
    INSERT INTO milestones (name, project, project_id, category_id, photo_needed, photos_uploaded)
    VALUES ('Foto Pulling Cable', project_record.name, project_record.id, implementasi_id, 10, 10);
    
    INSERT INTO milestones (name, project, project_id, category_id, photo_needed, photos_uploaded)
    VALUES ('Foto Proses Instal FAT (Pasang FAT di pole)', project_record.name, project_record.id, implementasi_id, 2, 0);
    
    INSERT INTO milestones (name, project, project_id, category_id, photo_needed, photos_uploaded)
    VALUES ('Foto Terminasi FAT', project_record.name, project_record.id, implementasi_id, 2, 0);
    
    INSERT INTO milestones (name, project, project_id, category_id, photo_needed, photos_uploaded)
    VALUES ('Foto Proses Instal FDT (Pasang FDT dipole)', project_record.name, project_record.id, implementasi_id, 1, 0);
    
    INSERT INTO milestones (name, project, project_id, category_id, photo_needed, photos_uploaded)
    VALUES ('Foto Terminasi FDT', project_record.name, project_record.id, implementasi_id, 1, 0);
    
    INSERT INTO milestones (name, project, project_id, category_id, photo_needed, photos_uploaded)
    VALUES ('Foto Proses Splacing FDT', project_record.name, project_record.id, implementasi_id, 1, 0);
    
    INSERT INTO milestones (name, project, project_id, category_id, photo_needed, photos_uploaded)
    VALUES ('Foto Proses Install Accesories', project_record.name, project_record.id, implementasi_id, 6, 4);
    
    INSERT INTO milestones (name, project, project_id, category_id, photo_needed, photos_uploaded)
    VALUES ('Foto Proses Install Label top cable', project_record.name, project_record.id, implementasi_id, 6, 0);
    
    INSERT INTO milestones (name, project, project_id, category_id, photo_needed, photos_uploaded)
    VALUES ('SN SPLITTER', project_record.name, project_record.id, implementasi_id, 0, 0);
    
    -- INSTALL FDT milestones
    INSERT INTO milestones (name, project, project_id, category_id, photo_needed, photos_uploaded)
    VALUES ('Foto FDT di Pole dari jarak jauh kelihatan Pole keseluruhan', project_record.name, project_record.id, install_fdt_id, 1, 0);
    
    INSERT INTO milestones (name, project, project_id, category_id, photo_needed, photos_uploaded)
    VALUES ('Foto FDT Tertutup dari dekat (yang sudah ada label namanya dan)', project_record.name, project_record.id, install_fdt_id, 1, 0);
    
    INSERT INTO milestones (name, project, project_id, category_id, photo_needed, photos_uploaded)
    VALUES ('Foto FDT terbuka dari dekat (posisi di POLE yg ada label pigtailnya)', project_record.name, project_record.id, install_fdt_id, 1, 0);
    
    INSERT INTO milestones (name, project, project_id, category_id, photo_needed, photos_uploaded)
    VALUES ('Foto Pondasi Pole FDT', project_record.name, project_record.id, install_fdt_id, 1, 0);
    
    INSERT INTO milestones (name, project, project_id, category_id, photo_needed, photos_uploaded)
    VALUES ('Foto Label top Cable', project_record.name, project_record.id, install_fdt_id, 1, 0);
    
    -- INSTALL FAT milestones
    INSERT INTO milestones (name, project, project_id, category_id, photo_needed, photos_uploaded)
    VALUES ('Foto FAT di Pole dari jarak jauh kelihatan Pole keseluruhan', project_record.name, project_record.id, install_fat_id, 1, 0);
    
    INSERT INTO milestones (name, project, project_id, category_id, photo_needed, photos_uploaded)
    VALUES ('Foto FAT Tertutup dari dekat (yang sudah ada label namanya)', project_record.name, project_record.id, install_fat_id, 1, 0);
    
    INSERT INTO milestones (name, project, project_id, category_id, photo_needed, photos_uploaded)
    VALUES ('Foto FAT terbuka dari dekat (posisi di Pole)', project_record.name, project_record.id, install_fat_id, 1, 0);
    
    INSERT INTO milestones (name, project, project_id, category_id, photo_needed, photos_uploaded)
    VALUES ('Foto Pondasi Pole FAT', project_record.name, project_record.id, install_fat_id, 1, 0);
    
    INSERT INTO milestones (name, project, project_id, category_id, photo_needed, photos_uploaded)
    VALUES ('Foto Label top Cable', project_record.name, project_record.id, install_fat_id, 1, 0);
    
    -- ELECTRICAL milestones
    INSERT INTO milestones (name, project, project_id, category_id)
    VALUES ('Foto Test OPM FDT before splitter', project_record.name, project_record.id, electrical_id);
    
    INSERT INTO milestones (name, project, project_id, category_id)
    VALUES ('Foto Test OPM FDT After splitter', project_record.name, project_record.id, electrical_id);
    
    INSERT INTO milestones (name, project, project_id, category_id)
    VALUES ('Foto Test OPM FAT (di beri label yang di dalamnya ada keterangan : Nama Cluster / Tanggal pengambilan test/Output FDT/Hasil OPM Test/Line No FAT/FAT Port no/ FDT ID)', 
            project_record.name, project_record.id, electrical_id);
    
    INSERT INTO milestones (name, project, project_id, category_id)
    VALUES ('Pdf OTDR Distribusi', project_record.name, project_record.id, electrical_id);
    
    INSERT INTO milestones (name, project, project_id, category_id)
    VALUES ('Pdf OTDR Subfeeder', project_record.name, project_record.id, electrical_id);
  END LOOP;
END $$;