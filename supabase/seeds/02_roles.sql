-- Seed file for roles

-- Insert roles first if they don't exist
DO $$
BEGIN
  -- Create roles if they don't exist
  INSERT INTO public.roles (name, description)
  VALUES 
    ('admin', 'Administrator with full access'),
    ('waspang', 'Field worker with limited access')
  ON CONFLICT (name) DO NOTHING;
END $$;