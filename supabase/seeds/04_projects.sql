-- Seed file for projects

-- Buat array untuk lokasi proyek
DO $$
DECLARE
  locations TEXT[] := ARRAY['Jakarta Utara', 'Jakarta Selatan', 'Jakarta Barat', 'Jakarta Timur', 'Jakarta Pusat', 
                           'Bandung', 'Surabaya', 'Medan', 'Makassar', 'Yogyakarta', 'Semarang', 'Palembang'];
  project_names TEXT[] := ARRAY['Fiber Installation', 'Network Expansion', 'Rural Connectivity', 'Urban Network Upgrade', 
                               'Fiber Backbone Project', 'Last Mile Connectivity', 'Metro Network', 'Enterprise Connectivity'];
  project_types TEXT[] := ARRAY['AERIAL', 'UNDERGROUND', 'MIXED'];
  project_name TEXT;
  location TEXT;
  start_date TIMESTAMP;
  end_date TIMESTAMP;
  description_templates TEXT[] := ARRAY[
    'Proyek pemasangan fiber optik di area %s untuk meningkatkan konektivitas internet',
    'Ekspansi jaringan fiber di wilayah %s untuk mendukung kebutuhan digital',
    'Proyek konektivitas %s untuk memperluas jangkauan jaringan fiber',
    'Upgrade infrastruktur jaringan di %s untuk meningkatkan kecepatan dan stabilitas'
  ];
  i INTEGER;
  project_id INTEGER;
  admin_id UUID;
  waspang_id UUID;
  -- Koordinat untuk lokasi di Indonesia (untuk latitude dan longitude)
  lat_coords NUMERIC[] := ARRAY[-6.1754, -6.2607, -6.1352, -6.2088, -6.1751, -6.9175, -7.2575, 3.5952, -5.1477, -7.7971, -7.0051, -2.9761];
  long_coords NUMERIC[] := ARRAY[106.8272, 106.8105, 106.8133, 106.8456, 106.8271, 107.6191, 112.7521, 98.6722, 119.4327, 110.3688, 110.4381, 104.7754];
  lat_idx INTEGER;
BEGIN
  -- Make sure we have admin users before proceeding
  SELECT id INTO admin_id FROM temp_admin_users ORDER BY random() LIMIT 1;
  
  -- If no admin users found, exit
  IF admin_id IS NULL THEN
    RAISE NOTICE 'No admin users found. Cannot create projects.';
    RETURN;
  END IF;

  -- Generate random projects (5-10 projects)
  FOR i IN 1..5 + floor(random() * 6)::int LOOP
    -- Pick random location and project type
    lat_idx := 1 + floor(random() * array_length(locations, 1))::int;
    location := locations[lat_idx];
    project_name := project_names[1 + floor(random() * array_length(project_names, 1))::int] || ' ' || location;
    
    -- Generate random dates (start date between 1-6 months ago, end date between 6-18 months from now)
    start_date := now() - (interval '1 month' * (1 + random() * 5));
    end_date := now() + (interval '6 month' * (1 + random() * 2));
    
    -- Insert project
    INSERT INTO projects (
      name, 
      location, 
      start_date, 
      end_date, 
      is_completed,
      description,
      project_type,
      homepass,
      man_power,
      jointer,
      latitude,
      longitude
    )
    VALUES (
      project_name,
      location,
      start_date,
      end_date,
      random() < 0.2, -- 20% chance of being completed
      format(
        description_templates[1 + floor(random() * array_length(description_templates, 1))::int],
        location
      ),
      project_types[1 + floor(random() * array_length(project_types, 1))::int],
      100 + floor(random() * 900)::int, -- Random homepass between 100-999
      2 + floor(random() * 8)::int, -- Random man_power between 2-9
      1 + floor(random() * 3)::int,  -- Random jointer between 1-3
      lat_coords[lat_idx] + (random() * 0.02 - 0.01), -- Latitude with small random variation
      long_coords[lat_idx] + (random() * 0.02 - 0.01)  -- Longitude with small random variation
    ) RETURNING id INTO project_id;
    
    -- Immediately assign at least one waspang user to this project
    SELECT id INTO waspang_id FROM temp_waspang_users ORDER BY random() LIMIT 1;
    
    -- Only proceed if we have both admin and waspang users
    IF admin_id IS NOT NULL AND waspang_id IS NOT NULL THEN
      INSERT INTO public.project_assignments (
        project_id,
        assigned_to,
        assigned_by,
        assigned_at
      )
      VALUES (
        project_id,
        waspang_id,
        admin_id,
        now() - (interval '1 day' * random() * 30)
      );
      
      -- Randomly assign some projects to admin users as well (100% chance)
      IF random() < 1 THEN
        INSERT INTO public.project_assignments (
          project_id,
          assigned_to,
          assigned_by,
          assigned_at
        )
        VALUES (
          project_id,
          admin_id, -- Assign to admin
          admin_id, -- Assigned by same admin
          now() - (interval '1 day' * random() * 30)
        );
      END IF;
    END IF;
  END LOOP;
END $$;