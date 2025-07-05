-- ============================================================================
-- REPORT TEMPLATES SEED DATA
-- ============================================================================

-- Clean up existing data
TRUNCATE TABLE report_template_items CASCADE;
TRUNCATE TABLE report_templates_parent_items CASCADE;
TRUNCATE TABLE report_templates CASCADE;

-- Insert template and items
DO $$
DECLARE
  template_id INTEGER;
  template_parent_item_id INTEGER;
  distribution_category_id INTEGER;
  subfeeder_category_id INTEGER;
BEGIN
  -- Get category IDs
  SELECT id INTO distribution_category_id FROM report_categories WHERE category_name = 'DISTRIBUTION';
  SELECT id INTO subfeeder_category_id FROM report_categories WHERE category_name = 'SUBFEEDER';
  
  -- Insert template
  INSERT INTO report_templates (template_name, description)
  VALUES ('Laporan Harian JATI KUDUS', 'Template untuk laporan harian pemasangan kabel fiber di JATI KUDUS SEG. 4')
  RETURNING id INTO template_id;
  
  -- ============================================================================
  -- DISTRIBUTION SECTION ITEMS
  -- ============================================================================
  
  -- 1. Digging Pole Hole Parent
  INSERT INTO report_templates_parent_items (template_id, item_parent_title, category_id)
  VALUES (template_id, 'Digging Pole Hole', distribution_category_id)
  RETURNING id INTO template_parent_item_id;
  
  -- Add parent item itself with quantity
  INSERT INTO report_template_items (template_id, template_parent_item_id, category_id, item_title, default_planned_quantity)
  VALUES (template_id, template_parent_item_id, distribution_category_id, 'Digging Pole Hole', 98);
  
  INSERT INTO report_template_items (template_id, template_parent_item_id, category_id, item_title, default_planned_quantity)
  VALUES 
    (template_id, template_parent_item_id, distribution_category_id, 'Install Pole 7m-4"', 92),
    (template_id, template_parent_item_id, distribution_category_id, 'Install Pole 7m-3" HC', 0),
    (template_id, template_parent_item_id, distribution_category_id, 'Install Pole 9m-4"', 6),
    (template_id, template_parent_item_id, distribution_category_id, 'Cor Pondasi', 98);
  
  -- 2. Cable Installation Parent
  INSERT INTO report_templates_parent_items (template_id, item_parent_title, category_id)
  VALUES (template_id, 'Cable Installation', distribution_category_id)
  RETURNING id INTO template_parent_item_id;
  
  -- Add parent item itself with quantity
  INSERT INTO report_template_items (template_id, template_parent_item_id, category_id, item_title, default_planned_quantity)
  VALUES (template_id, template_parent_item_id, distribution_category_id, 'Cable Installation', 13204);
  
  INSERT INTO report_template_items (template_id, template_parent_item_id, category_id, item_title, default_planned_quantity)
  VALUES 
    (template_id, template_parent_item_id, distribution_category_id, '48C/4T', 0),
    (template_id, template_parent_item_id, distribution_category_id, '72C/4T', 0),
    (template_id, template_parent_item_id, distribution_category_id, '96C/8T', 0),
    (template_id, template_parent_item_id, distribution_category_id, '144C/12T', 13204);
  
  -- 3. Closure Parent
  INSERT INTO report_templates_parent_items (template_id, item_parent_title, category_id)
  VALUES (template_id, 'Closure', distribution_category_id)
  RETURNING id INTO template_parent_item_id;
  
  INSERT INTO report_template_items (template_id, template_parent_item_id, category_id, item_title, default_planned_quantity)
  VALUES 
    (template_id, template_parent_item_id, distribution_category_id, 'Fiber Optic Joint Closure Type In-line 48 Core', 0),
    (template_id, template_parent_item_id, distribution_category_id, 'Fiber Optic Joint Closure Type Dome 48 Core', 0),
    (template_id, template_parent_item_id, distribution_category_id, 'Fiber Optic Joint Closure Type In-line 144 Core', 3),
    (template_id, template_parent_item_id, distribution_category_id, 'Fiber Optic Joint Closure Type Dome 288 Core', 0);
  
  -- 4. Accessoris Parent
  INSERT INTO report_templates_parent_items (template_id, item_parent_title, category_id)
  VALUES (template_id, 'Accessoris (1 set every acc)', distribution_category_id)
  RETURNING id INTO template_parent_item_id;
  
  INSERT INTO report_template_items (template_id, template_parent_item_id, category_id, item_title, default_planned_quantity)
  VALUES 
    (template_id, template_parent_item_id, distribution_category_id, 'Cable loop holder/plat strip/Cable hanger', 38),
    (template_id, template_parent_item_id, distribution_category_id, 'Plate belt 20mm', 284),
    (template_id, template_parent_item_id, distribution_category_id, 'Suspension clamp', 139),
    (template_id, template_parent_item_id, distribution_category_id, 'Buldog grip', 0),
    (template_id, template_parent_item_id, distribution_category_id, 'Clamps Dead end Fittings/clamp buaya', 0),
    (template_id, template_parent_item_id, distribution_category_id, 'Bahan Pondasi tiang', 38),
    (template_id, template_parent_item_id, distribution_category_id, 'Steel clamp', 139),
    (template_id, template_parent_item_id, distribution_category_id, 'Pole clamp single', 266),
    (template_id, template_parent_item_id, distribution_category_id, 'HELICAL DEAD END DIAMETER 15.7-17.0 MM', 539),
    (template_id, template_parent_item_id, distribution_category_id, 'Extention Arm', 0),
    (template_id, template_parent_item_id, distribution_category_id, 'Strand wire', 0);
  
  -- 5. Label Parent
  INSERT INTO report_templates_parent_items (template_id, item_parent_title, category_id)
  VALUES (template_id, 'Label', distribution_category_id)
  RETURNING id INTO template_parent_item_id;
  
  INSERT INTO report_template_items (template_id, template_parent_item_id, category_id, item_title, default_planned_quantity)
  VALUES 
    (template_id, template_parent_item_id, distribution_category_id, 'Label Cable', 266),
    (template_id, template_parent_item_id, distribution_category_id, 'Lable Pole', 98);
  
  -- 6. Splicing Parent
  INSERT INTO report_templates_parent_items (template_id, item_parent_title, category_id)
  VALUES (template_id, 'Splicing', distribution_category_id)
  RETURNING id INTO template_parent_item_id;
  
  INSERT INTO report_template_items (template_id, template_parent_item_id, category_id, item_title, default_planned_quantity)
  VALUES 
    (template_id, template_parent_item_id, distribution_category_id, 'Joint Closure', 576);
  
  -- Additional DISTRIBUTION items (without specific parent groups)
  INSERT INTO report_templates_parent_items (template_id, item_parent_title, category_id)
  VALUES (template_id, 'Additional Distribution Items', distribution_category_id)
  RETURNING id INTO template_parent_item_id;
  
  INSERT INTO report_template_items (template_id, template_parent_item_id, category_id, item_title, default_planned_quantity)
  VALUES 
    (template_id, template_parent_item_id, distribution_category_id, 'FDT 1 LINE A - 48C (mtr)', 1759),
    (template_id, template_parent_item_id, distribution_category_id, 'FDT 1 LINE B - 24C (mtr)', 2313),
    (template_id, template_parent_item_id, distribution_category_id, 'FDT 2 LINE A - 48C (mtr)', 1416),
    (template_id, template_parent_item_id, distribution_category_id, 'FDT 2 LINE B - 24C (mtr)', 998),
    (template_id, template_parent_item_id, distribution_category_id, 'FDT 48C (Unit)', 1),
    (template_id, template_parent_item_id, distribution_category_id, 'FDT 96C (Unit)', 1),
    (template_id, template_parent_item_id, distribution_category_id, 'FAT (Unit)', 44),
    (template_id, template_parent_item_id, distribution_category_id, 'Splicing FDT', 44),
    (template_id, template_parent_item_id, distribution_category_id, 'Splicing FAT', 44);
  
  -- ACCESORIES group
  INSERT INTO report_templates_parent_items (template_id, item_parent_title, category_id)
  VALUES (template_id, 'ACCESORIES', distribution_category_id)
  RETURNING id INTO template_parent_item_id;
  
  INSERT INTO report_template_items (template_id, template_parent_item_id, category_id, item_title, default_planned_quantity)
  VALUES 
    (template_id, template_parent_item_id, distribution_category_id, 'Cable Hanger', 46),
    (template_id, template_parent_item_id, distribution_category_id, 'Plate Belt', 239),
    (template_id, template_parent_item_id, distribution_category_id, 'Suspension Clamp', 55),
    (template_id, template_parent_item_id, distribution_category_id, 'Buldog Grip', 183),
    (template_id, template_parent_item_id, distribution_category_id, 'Strand Wire', 1223),
    (template_id, template_parent_item_id, distribution_category_id, 'Dead end', 146),
    (template_id, template_parent_item_id, distribution_category_id, 'Pole clamp single', 154);
  
  -- Items Done
  INSERT INTO report_templates_parent_items (template_id, item_parent_title, category_id)
  VALUES (template_id, 'Items Done', distribution_category_id)
  RETURNING id INTO template_parent_item_id;
  
  INSERT INTO report_template_items (template_id, template_parent_item_id, category_id, item_title, default_planned_quantity)
  VALUES 
    (template_id, template_parent_item_id, distribution_category_id, 'Items Done >>', 37754);
  
  -- ============================================================================
  -- SUB FEEDER SECTION ITEMS
  -- ============================================================================
  
  INSERT INTO report_templates_parent_items (template_id, item_parent_title, category_id)
  VALUES (template_id, 'SUB FEEDER', subfeeder_category_id)
  RETURNING id INTO template_parent_item_id;
  
  INSERT INTO report_template_items (template_id, template_parent_item_id, category_id, item_title, default_planned_quantity)
  VALUES 
    (template_id, template_parent_item_id, subfeeder_category_id, 'Digging Pole Hole', 0),
    (template_id, template_parent_item_id, subfeeder_category_id, 'Install Pole 7m-4"', 0),
    (template_id, template_parent_item_id, subfeeder_category_id, 'Install Pole 9m-4"', 0),
    (template_id, template_parent_item_id, subfeeder_category_id, 'INSTALASI KABEL ADSS 48 cores', 0),
    (template_id, template_parent_item_id, subfeeder_category_id, 'NEW JOINT CLOSURE - 144 cores', 0),
    (template_id, template_parent_item_id, subfeeder_category_id, 'SPLICING CLOSURE', 0),
    (template_id, template_parent_item_id, subfeeder_category_id, 'Accessories SF', 0),
    (template_id, template_parent_item_id, subfeeder_category_id, 'Cable Hanger', 0),
    (template_id, template_parent_item_id, subfeeder_category_id, 'Plate Belt', 0),
    (template_id, template_parent_item_id, subfeeder_category_id, 'Suspension Clamp', 0),
    (template_id, template_parent_item_id, subfeeder_category_id, 'Wartel', 0),
    (template_id, template_parent_item_id, subfeeder_category_id, 'Dead end', 0),
    (template_id, template_parent_item_id, subfeeder_category_id, 'Items Done SF', 0);

  -- Add independent template items (without parent) for demonstration
  INSERT INTO report_template_items (template_id, template_parent_item_id, category_id, item_title, default_planned_quantity)
  VALUES 
    (template_id, NULL, distribution_category_id, 'Site Survey', 0),
    (template_id, NULL, distribution_category_id, 'Documentation', 0),
    (template_id, NULL, subfeeder_category_id, 'Quality Control', 0),
    (template_id, NULL, subfeeder_category_id, 'Final Testing', 0);
  
  RAISE NOTICE 'Template and items created successfully with ID: %', template_id;
  
END $$;