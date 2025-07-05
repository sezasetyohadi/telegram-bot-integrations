-- Seed file for users

-- Aktifkan ekstensi yang diperlukan
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Insert dummy admin users using Supabase's auth.users() function
DO $$
DECLARE
  admin1_id UUID;
  admin2_id UUID;
  admin1_email TEXT := 'admin1@example.com';
  admin2_email TEXT := 'admin2@example.com';
  admin1_username TEXT := 'admin1';
  admin2_username TEXT := 'admin2';
BEGIN
  -- Check if super admin user already exists
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = admin1_email) THEN
    -- Create super admin user
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      recovery_sent_at,
      last_sign_in_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      confirmation_token,
      email_change,
      email_change_token_new,
      recovery_token
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      uuid_generate_v4(),
      'authenticated',
      'authenticated',
      admin1_email,
      crypt('password123', gen_salt('bf')),
      now(),
      now(),
      now(),
      '{"provider":"email","providers":["email"]}',
      '{}',
      now(),
      now(),
      '',
      '',
      '',
      ''
    ) RETURNING id INTO admin1_id;
    
    -- Hapus role default yang mungkin sudah ditambahkan oleh trigger
    DELETE FROM public.user_roles WHERE user_id = admin1_id;
    
    -- Assign admin roles with username instead of email and set as super admin
    INSERT INTO public.user_roles (user_id, role_id, user_name, is_super_admin)
    VALUES 
      (admin1_id, (SELECT id FROM public.roles WHERE name = 'admin'), admin1_username, true)
    ON CONFLICT (user_id, role_id) DO UPDATE SET is_super_admin = true, user_name = admin1_username;
  ELSE
    -- Get existing admin ID
    SELECT id INTO admin1_id FROM auth.users WHERE email = admin1_email;
    
    -- Hapus role lain yang mungkin ada
    DELETE FROM public.user_roles WHERE user_id = admin1_id AND role_id != (SELECT id FROM public.roles WHERE name = 'admin');
    
    -- Update user_name and set as super admin
    UPDATE public.user_roles 
    SET user_name = admin1_username, is_super_admin = true
    WHERE user_id = admin1_id AND role_id = (SELECT id FROM public.roles WHERE name = 'admin');
    
    -- Pastikan user memiliki role admin
    INSERT INTO public.user_roles (user_id, role_id, user_name, is_super_admin)
    VALUES 
      (admin1_id, (SELECT id FROM public.roles WHERE name = 'admin'), admin1_username, true)
    ON CONFLICT (user_id, role_id) DO UPDATE SET is_super_admin = true, user_name = admin1_username;
  END IF;
  
  -- Check if regular admin user already exists
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = admin2_email) THEN
    -- Create regular admin user
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      recovery_sent_at,
      last_sign_in_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      confirmation_token,
      email_change,
      email_change_token_new,
      recovery_token
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      uuid_generate_v4(),
      'authenticated',
      'authenticated',
      admin2_email,
      crypt('password123', gen_salt('bf')),
      now(),
      now(),
      now(),
      '{"provider":"email","providers":["email"]}',
      '{}',
      now(),
      now(),
      '',
      '',
      '',
      ''
    ) RETURNING id INTO admin2_id;
    
    -- Hapus role default yang mungkin sudah ditambahkan oleh trigger
    DELETE FROM public.user_roles WHERE user_id = admin2_id;
    
    -- Assign admin roles with username instead of email and set as regular admin (not super admin)
    INSERT INTO public.user_roles (user_id, role_id, user_name, is_super_admin)
    VALUES 
      (admin2_id, (SELECT id FROM public.roles WHERE name = 'admin'), admin2_username, false)
    ON CONFLICT (user_id, role_id) DO UPDATE SET is_super_admin = false, user_name = admin2_username;
  ELSE
    -- Get existing admin ID
    SELECT id INTO admin2_id FROM auth.users WHERE email = admin2_email;
    
    -- Hapus role lain yang mungkin ada
    DELETE FROM public.user_roles WHERE user_id = admin2_id AND role_id != (SELECT id FROM public.roles WHERE name = 'admin');
    
    -- Update user_name and set as regular admin
    UPDATE public.user_roles 
    SET user_name = admin2_username, is_super_admin = false
    WHERE user_id = admin2_id AND role_id = (SELECT id FROM public.roles WHERE name = 'admin');
    
    -- Pastikan user memiliki role admin
    INSERT INTO public.user_roles (user_id, role_id, user_name, is_super_admin)
    VALUES 
      (admin2_id, (SELECT id FROM public.roles WHERE name = 'admin'), admin2_username, false)
    ON CONFLICT (user_id, role_id) DO UPDATE SET is_super_admin = false, user_name = admin2_username;
  END IF;
  
  -- Store admin_ids in a temporary table for use in other blocks
  DROP TABLE IF EXISTS temp_admin_users;
  CREATE TEMPORARY TABLE temp_admin_users (
    id UUID,
    is_super_admin BOOLEAN
  );
  
  INSERT INTO temp_admin_users VALUES 
    (admin1_id, true),
    (admin2_id, false);
END $$;

-- Insert dummy waspang users
DO $$
DECLARE
  waspang_id UUID;
  waspang_ids UUID[] := ARRAY[]::UUID[];
  i INTEGER;
  waspang_email TEXT;
  waspang_username TEXT;
BEGIN
  FOR i IN 1..5 LOOP
    waspang_email := 'waspang' || i || '@example.com';
    waspang_username := 'waspang' || i;
    
    -- Check if user already exists
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = waspang_email) THEN
      -- Create waspang user
      INSERT INTO auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        recovery_sent_at,
        last_sign_in_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        confirmation_token,
        email_change,
        email_change_token_new,
        recovery_token
      ) VALUES (
        '00000000-0000-0000-0000-000000000000',
        uuid_generate_v4(),
        'authenticated',
        'authenticated',
        waspang_email,
        crypt('password123', gen_salt('bf')),
        now(),
        now(),
        now(),
        '{"provider":"email","providers":["email"]}',
        '{}',
        now(),
        now(),
        '',
        '',
        '',
        ''
      ) RETURNING id INTO waspang_id;
      
      -- Hapus role default yang mungkin sudah ditambahkan oleh trigger
      DELETE FROM public.user_roles WHERE user_id = waspang_id;
      
      -- Assign waspang role with username instead of email
      INSERT INTO public.user_roles (user_id, role_id, user_name, is_super_admin)
      VALUES (waspang_id, (SELECT id FROM public.roles WHERE name = 'waspang'), waspang_username, false)
      ON CONFLICT (user_id, role_id) DO UPDATE SET user_name = waspang_username, is_super_admin = false;
    ELSE
      -- Get existing waspang ID
      SELECT id INTO waspang_id FROM auth.users WHERE email = waspang_email;
      
      -- Hapus role lain yang mungkin ada
      DELETE FROM public.user_roles WHERE user_id = waspang_id AND role_id != (SELECT id FROM public.roles WHERE name = 'waspang');
      
      -- Update user_name if needed
      UPDATE public.user_roles 
      SET user_name = waspang_username, is_super_admin = false
      WHERE user_id = waspang_id AND role_id = (SELECT id FROM public.roles WHERE name = 'waspang');
      
      -- Pastikan user memiliki role waspang
      INSERT INTO public.user_roles (user_id, role_id, user_name, is_super_admin)
      VALUES (waspang_id, (SELECT id FROM public.roles WHERE name = 'waspang'), waspang_username, false)
      ON CONFLICT (user_id, role_id) DO UPDATE SET user_name = waspang_username, is_super_admin = false;
    END IF;
    
    -- Store waspang ID in array for later use
    waspang_ids := array_append(waspang_ids, waspang_id);
  END LOOP;

  -- Store waspang_ids in a temporary table for use in other blocks
  DROP TABLE IF EXISTS temp_waspang_users;
  CREATE TEMPORARY TABLE temp_waspang_users (
    id UUID
  );
  
  INSERT INTO temp_waspang_users
  SELECT unnest(waspang_ids);
END $$;