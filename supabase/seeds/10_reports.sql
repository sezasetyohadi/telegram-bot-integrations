-- ============================================================================
-- REPORT ITEMS SEED DATA - UPDATED FOR ALL PROJECTS
-- ============================================================================

DO $$ 
DECLARE
  project_record RECORD;
  target_template_id INTEGER;
  item_id INTEGER;
  impl_id INTEGER;
  distribution_category_id INTEGER;
  subfeeder_category_id INTEGER;
  parent_item_id INTEGER;
BEGIN
  -- Get template that was created
  SELECT id INTO target_template_id FROM report_templates WHERE template_name = 'Laporan Harian JATI KUDUS' LIMIT 1;
  
  -- Get category IDs
  SELECT id INTO distribution_category_id FROM report_categories WHERE category_name = 'DISTRIBUTION';
  SELECT id INTO subfeeder_category_id FROM report_categories WHERE category_name = 'SUBFEEDER';
  
  -- Loop through ALL projects
  FOR project_record IN SELECT id FROM projects LOOP
    
    -- ============================================================================
    -- DISTRIBUTION PARENT ITEMS (for each project)
    -- ============================================================================
    
    -- Insert parent items for DISTRIBUTION category for current project
    INSERT INTO report_parent_items (project_id, parent_title, category_id) 
    SELECT project_record.id, 'Digging Pole Hole', distribution_category_id
    WHERE NOT EXISTS (SELECT 1 FROM report_parent_items WHERE project_id = project_record.id AND parent_title = 'Digging Pole Hole' AND category_id = distribution_category_id);
    
    INSERT INTO report_parent_items (project_id, parent_title, category_id) 
    SELECT project_record.id, 'Cable Installation', distribution_category_id
    WHERE NOT EXISTS (SELECT 1 FROM report_parent_items WHERE project_id = project_record.id AND parent_title = 'Cable Installation' AND category_id = distribution_category_id);
    
    INSERT INTO report_parent_items (project_id, parent_title, category_id) 
    SELECT project_record.id, 'Closure', distribution_category_id
    WHERE NOT EXISTS (SELECT 1 FROM report_parent_items WHERE project_id = project_record.id AND parent_title = 'Closure' AND category_id = distribution_category_id);
    
    INSERT INTO report_parent_items (project_id, parent_title, category_id) 
    SELECT project_record.id, 'Accessoris (1 set every acc)', distribution_category_id
    WHERE NOT EXISTS (SELECT 1 FROM report_parent_items WHERE project_id = project_record.id AND parent_title = 'Accessoris (1 set every acc)' AND category_id = distribution_category_id);
    
    INSERT INTO report_parent_items (project_id, parent_title, category_id) 
    SELECT project_record.id, 'Label', distribution_category_id
    WHERE NOT EXISTS (SELECT 1 FROM report_parent_items WHERE project_id = project_record.id AND parent_title = 'Label' AND category_id = distribution_category_id);
    
    INSERT INTO report_parent_items (project_id, parent_title, category_id) 
    SELECT project_record.id, 'Splicing', distribution_category_id
    WHERE NOT EXISTS (SELECT 1 FROM report_parent_items WHERE project_id = project_record.id AND parent_title = 'Splicing' AND category_id = distribution_category_id);
    
    INSERT INTO report_parent_items (project_id, parent_title, category_id) 
    SELECT project_record.id, 'Additional Distribution Items', distribution_category_id
    WHERE NOT EXISTS (SELECT 1 FROM report_parent_items WHERE project_id = project_record.id AND parent_title = 'Additional Distribution Items' AND category_id = distribution_category_id);
    
    INSERT INTO report_parent_items (project_id, parent_title, category_id) 
    SELECT project_record.id, 'ACCESORIES', distribution_category_id
    WHERE NOT EXISTS (SELECT 1 FROM report_parent_items WHERE project_id = project_record.id AND parent_title = 'ACCESORIES' AND category_id = distribution_category_id);
    
    INSERT INTO report_parent_items (project_id, parent_title, category_id) 
    SELECT project_record.id, 'Items Done', distribution_category_id
    WHERE NOT EXISTS (SELECT 1 FROM report_parent_items WHERE project_id = project_record.id AND parent_title = 'Items Done' AND category_id = distribution_category_id);
    
    -- Insert parent items for SUBFEEDER category for current project
    INSERT INTO report_parent_items (project_id, parent_title, category_id) 
    SELECT project_record.id, 'SUB FEEDER', subfeeder_category_id
    WHERE NOT EXISTS (SELECT 1 FROM report_parent_items WHERE project_id = project_record.id AND parent_title = 'SUB FEEDER' AND category_id = subfeeder_category_id);
    
    -- ============================================================================
    -- DISTRIBUTION REPORT ITEMS FOR CURRENT PROJECT
    -- ============================================================================
    
    -- 1. Digging Pole Hole items
    SELECT id INTO parent_item_id FROM report_parent_items WHERE project_id = project_record.id AND parent_title = 'Digging Pole Hole' AND category_id = distribution_category_id;
    INSERT INTO report_items (project_id, parent_item_id, category_id, item_title, planned_quantity, created_by)
    VALUES 
    (project_record.id, parent_item_id, distribution_category_id, 'Digging Pole Hole', 98, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Install Pole 7m-4"', 92, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Install Pole 7m-3" HC', 0, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Install Pole 9m-4"', 6, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Cor Pondasi', 98, 'system');
    
    -- 2. Cable Installation items
    SELECT id INTO parent_item_id FROM report_parent_items WHERE project_id = project_record.id AND parent_title = 'Cable Installation' AND category_id = distribution_category_id;
    INSERT INTO report_items (project_id, parent_item_id, category_id, item_title, planned_quantity, created_by)
    VALUES 
    (project_record.id, parent_item_id, distribution_category_id, 'Cable Installation', 13204, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, '48C/4T', 0, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, '72C/4T', 0, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, '96C/8T', 0, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, '144C/12T', 13204, 'system');

    -- Example of items without parent (directly at same level as parent items)
    INSERT INTO report_items (project_id, parent_item_id, category_id, item_title, planned_quantity, created_by)
    VALUES 
    (project_record.id, NULL, distribution_category_id, 'Independent Task 1', 50, 'system'),
    (project_record.id, NULL, distribution_category_id, 'Independent Task 2', 25, 'system');
    
    -- 3. Closure items
    SELECT id INTO parent_item_id FROM report_parent_items WHERE project_id = project_record.id AND parent_title = 'Closure' AND category_id = distribution_category_id;
    INSERT INTO report_items (project_id, parent_item_id, category_id, item_title, planned_quantity, created_by)
    VALUES 
    (project_record.id, parent_item_id, distribution_category_id, 'Fiber Optic Joint Closure Type In-line 48 Core', 0, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Fiber Optic Joint Closure Type Dome 48 Core', 0, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Fiber Optic Joint Closure Type In-line 144 Core', 3, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Fiber Optic Joint Closure Type Dome 288 Core', 0, 'system');
    
    -- 4. Accessoris items
    SELECT id INTO parent_item_id FROM report_parent_items WHERE project_id = project_record.id AND parent_title = 'Accessoris (1 set every acc)' AND category_id = distribution_category_id;
    INSERT INTO report_items (project_id, parent_item_id, category_id, item_title, planned_quantity, created_by)
    VALUES 
    (project_record.id, parent_item_id, distribution_category_id, 'Cable loop holder/plat strip/Cable hanger', 38, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Plate belt 20mm', 284, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Suspension clamp', 139, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Buldog grip', 0, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Clamps Dead end Fittings/clamp buaya', 0, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Bahan Pondasi tiang', 38, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Steel clamp', 139, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Pole clamp single', 266, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'HELICAL DEAD END DIAMETER 15.7-17.0 MM', 539, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Extention Arm', 0, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Strand wire', 0, 'system');
    
    -- 5. Label items
    SELECT id INTO parent_item_id FROM report_parent_items WHERE project_id = project_record.id AND parent_title = 'Label' AND category_id = distribution_category_id;
    INSERT INTO report_items (project_id, parent_item_id, category_id, item_title, planned_quantity, created_by)
    VALUES 
    (project_record.id, parent_item_id, distribution_category_id, 'Label Cable', 266, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Lable Pole', 98, 'system');
    
    -- 6. Splicing items
    SELECT id INTO parent_item_id FROM report_parent_items WHERE project_id = project_record.id AND parent_title = 'Splicing' AND category_id = distribution_category_id;
    INSERT INTO report_items (project_id, parent_item_id, category_id, item_title, planned_quantity, created_by)
    VALUES 
    (project_record.id, parent_item_id, distribution_category_id, 'Joint Closure', 576, 'system');
    
    -- 7. Additional Distribution Items
    SELECT id INTO parent_item_id FROM report_parent_items WHERE project_id = project_record.id AND parent_title = 'Additional Distribution Items' AND category_id = distribution_category_id;
    INSERT INTO report_items (project_id, parent_item_id, category_id, item_title, planned_quantity, created_by)
    VALUES 
    (project_record.id, parent_item_id, distribution_category_id, 'FDT 1 LINE A - 48C (mtr)', 1759, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'FDT 1 LINE B - 24C (mtr)', 2313, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'FDT 2 LINE A - 48C (mtr)', 1416, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'FDT 2 LINE B - 24C (mtr)', 998, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'FDT 48C (Unit)', 1, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'FDT 96C (Unit)', 1, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'FAT (Unit)', 44, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Splicing FDT', 44, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Splicing FAT', 44, 'system');
    
    -- 8. ACCESORIES items
    SELECT id INTO parent_item_id FROM report_parent_items WHERE project_id = project_record.id AND parent_title = 'ACCESORIES' AND category_id = distribution_category_id;
    INSERT INTO report_items (project_id, parent_item_id, category_id, item_title, planned_quantity, created_by)
    VALUES 
    (project_record.id, parent_item_id, distribution_category_id, 'Cable Hanger', 46, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Plate Belt', 239, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Suspension Clamp', 55, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Buldog Grip', 183, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Strand Wire', 1223, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Dead end', 146, 'system'),
    (project_record.id, parent_item_id, distribution_category_id, 'Pole clamp single', 154, 'system');
    
    -- Example of more independent items (without parent)
    INSERT INTO report_items (project_id, parent_item_id, category_id, item_title, planned_quantity, created_by)
    VALUES 
    (project_record.id, NULL, distribution_category_id, 'Site Survey', 100, 'system'),
    (project_record.id, NULL, distribution_category_id, 'Documentation', 75, 'system');
    
    -- 9. Items Done
    SELECT id INTO parent_item_id FROM report_parent_items WHERE project_id = project_record.id AND parent_title = 'Items Done' AND category_id = distribution_category_id;
    INSERT INTO report_items (project_id, parent_item_id, category_id, item_title, planned_quantity, created_by)
    VALUES 
    (project_record.id, parent_item_id, distribution_category_id, 'Items Done >>', 37754, 'system');
    
    -- ============================================================================
    -- SUB FEEDER REPORT ITEMS FOR CURRENT PROJECT
    -- ============================================================================
    
    SELECT id INTO parent_item_id FROM report_parent_items WHERE project_id = project_record.id AND parent_title = 'SUB FEEDER' AND category_id = subfeeder_category_id;
    INSERT INTO report_items (project_id, parent_item_id, category_id, item_title, planned_quantity, created_by)
    VALUES 
    (project_record.id, parent_item_id, subfeeder_category_id, 'Digging Pole Hole', 0, 'system'),
    (project_record.id, parent_item_id, subfeeder_category_id, 'Install Pole 7m-4"', 0, 'system'),
    (project_record.id, parent_item_id, subfeeder_category_id, 'Install Pole 9m-4"', 0, 'system'),
    (project_record.id, parent_item_id, subfeeder_category_id, 'INSTALASI KABEL ADSS 48 cores', 0, 'system'),
    (project_record.id, parent_item_id, subfeeder_category_id, 'NEW JOINT CLOSURE - 144 cores', 0, 'system'),
    (project_record.id, parent_item_id, subfeeder_category_id, 'SPLICING CLOSURE', 0, 'system'),
    (project_record.id, parent_item_id, subfeeder_category_id, 'Accessories SF', 0, 'system'),
    (project_record.id, parent_item_id, subfeeder_category_id, 'Cable Hanger', 0, 'system'),
    (project_record.id, parent_item_id, subfeeder_category_id, 'Plate Belt', 0, 'system'),
    (project_record.id, parent_item_id, subfeeder_category_id, 'Suspension Clamp', 0, 'system'),
    (project_record.id, parent_item_id, subfeeder_category_id, 'Wartel', 0, 'system'),
    (project_record.id, parent_item_id, subfeeder_category_id, 'Dead end', 0, 'system');
    
    -- ============================================================================
    -- SAMPLE IMPLEMENTATIONS FOR CURRENT PROJECT
    -- ============================================================================
    
    -- Add some sample implementations for items with planned quantities > 0
    FOR item_id IN 
      SELECT ri.id FROM report_items ri
      JOIN report_parent_items rpi ON ri.parent_item_id = rpi.id
      WHERE rpi.project_id = project_record.id 
      AND ri.planned_quantity > 0 
      LIMIT 10
    LOOP
      -- Add implementation for today
      INSERT INTO report_implementations (report_item_id, daily_quantity, implementation_date)
      VALUES (
        item_id, 
        (SELECT planned_quantity * 0.1 FROM report_items WHERE id = item_id),
        CURRENT_DATE
      );
      
      -- Add implementation for yesterday
      INSERT INTO report_implementations (report_item_id, daily_quantity, implementation_date)
      VALUES (
        item_id, 
        (SELECT planned_quantity * 0.05 FROM report_items WHERE id = item_id),
        CURRENT_DATE - INTERVAL '1 day'
      );
    END LOOP;
    
    -- Insert sample ATP data for current project
    INSERT INTO report_atp (project_id, report_date, civil_work, opm_test)
    VALUES 
    (project_record.id, CURRENT_DATE, '2025-06-16', '2025-06-17'),
    (project_record.id, CURRENT_DATE - INTERVAL '1 day', NULL, '2025-06-16'),
    (project_record.id, CURRENT_DATE - INTERVAL '2 days', NULL, NULL);
    
    -- Insert sample work time data for current project
    INSERT INTO report_work_time (project_id, report_date, start_time, end_time)
    VALUES 
    (project_record.id, CURRENT_DATE, '08:00:00', '17:00:00'),
    (project_record.id, CURRENT_DATE - INTERVAL '1 day', '08:30:00', '16:30:00'),
    (project_record.id, CURRENT_DATE - INTERVAL '2 days', '09:00:00', '17:30:00');
    
    -- Insert sample issues data for current project
    INSERT INTO report_issues (project_id, report_date, issue_description)
    VALUES 
    (project_record.id, CURRENT_DATE, 'Weather conditions affecting cable installation progress'),
    (project_record.id, CURRENT_DATE - INTERVAL '1 day', 'Equipment maintenance required for drilling machine'),
    (project_record.id, CURRENT_DATE - INTERVAL '2 days', 'Material delivery delayed due to traffic conditions');
    
    -- Insert sample tomorrow plans data for current project
    INSERT INTO report_tomorrow_plans (project_id, report_date, plan_description)
    VALUES 
    (project_record.id, CURRENT_DATE, 'Continue cable installation on main distribution line'),
    (project_record.id, CURRENT_DATE, 'Complete closure installation for section A'),
    (project_record.id, CURRENT_DATE, 'Begin pole hole digging for next phase'),
    (project_record.id, CURRENT_DATE - INTERVAL '1 day', 'Install remaining accessories for distribution points'),
    (project_record.id, CURRENT_DATE - INTERVAL '1 day', 'Conduct quality testing on completed sections');
    
  END LOOP; -- End of project loop
  
END $$;