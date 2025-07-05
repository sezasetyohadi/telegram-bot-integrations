-- Seed file untuk template milestone
DO $$
DECLARE
  implementasi_id INTEGER;
  install_fdt_id INTEGER;
  install_fat_id INTEGER;
  electrical_id INTEGER;
BEGIN
  
  -- Ambil ID kategori
  SELECT id INTO implementasi_id FROM categories WHERE name = 'IMPLEMENTASI' LIMIT 1;
  SELECT id INTO install_fdt_id FROM categories WHERE name = 'INSTALL FDT' LIMIT 1;
  SELECT id INTO install_fat_id FROM categories WHERE name = 'INSTALL FAT' LIMIT 1;
  SELECT id INTO electrical_id FROM categories WHERE name = 'ELECTRICAL' LIMIT 1;
  
  -- Template untuk IMPLEMENTASI
  INSERT INTO milestone_templates (name, category_id, photo_needed)
  VALUES 
    ('Foto Digging Pole (Menggali Lubang Untuk tanam Pole)', implementasi_id, 6),
    ('Foto Mengukur Kedalaman Lubang galian', implementasi_id, 6),
    ('Foto Prepare Install Pole', implementasi_id, 6),
    ('Foto Install Pole', implementasi_id, 6),
    ('Foto Pulling Cable', implementasi_id, 10),
    ('Foto Proses Instal FAT (Pasang FAT di pole)', implementasi_id, 2),
    ('Foto Terminasi FAT', implementasi_id, 2),
    ('Foto Proses Instal FDT (Pasang FDT dipole)', implementasi_id, 1),
    ('Foto Terminasi FDT', implementasi_id, 1),
    ('Foto Proses Splacing FDT', implementasi_id, 1),
    ('Foto Proses Install Accesories', implementasi_id, 6),
    ('Foto Proses Install Label top cable', implementasi_id, 6),
    ('SN SPLITTER', implementasi_id, 0);
  
  -- Template untuk INSTALL FDT
  INSERT INTO milestone_templates (name, category_id, photo_needed)
  VALUES
    ('Foto FDT di Pole dari jarak jauh kelihatan Pole keseluruhan', install_fdt_id, 1),
    ('Foto FDT Tertutup dari dekat (yang sudah ada label namanya dan)', install_fdt_id, 1),
    ('Foto FDT terbuka dari dekat (posisi di POLE yg ada label pigtailnya)', install_fdt_id, 1),
    ('Foto Pondasi Pole FDT', install_fdt_id, 1),
    ('Foto Label top Cable', install_fdt_id, 1);
  
  -- Template untuk INSTALL FAT
  INSERT INTO milestone_templates (name, category_id, photo_needed)
  VALUES
    ('Foto FAT di Pole dari jarak jauh kelihatan Pole keseluruhan', install_fat_id, 0),
    ('Foto FAT Tertutup dari dekat (yang sudah ada label namanya)', install_fat_id, 0),
    ('Foto FAT terbuka dari dekat (posisi di Pole)', install_fat_id, 0),
    ('Foto Pondasi Pole FAT', install_fat_id, 0),
    ('Foto Label top Cable', install_fat_id, 0);
  
  -- Template untuk ELECTRICAL
  INSERT INTO milestone_templates (name, category_id, photo_needed)
  VALUES
    ('Foto Test OPM FDT before splitter', electrical_id, 0),
    ('Foto Test OPM FDT After splitter', electrical_id, 0),
    ('Foto Test OPM FAT (di beri label yang di dalamnya ada keterangan : Nama Cluster / Tanggal pengambilan test/Output FDT/Hasil OPM Test/Line No FAT/FAT Port no/FDT ID)', electrical_id, 0),
    ('Pdf OTDR Distribusi', electrical_id, 0),
    ('Pdf OTDR Subfeeder', electrical_id, 0);
END $$;