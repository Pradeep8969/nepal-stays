-- Quick admin fix - disable RLS temporarily and rebuild
-- Run this in Supabase SQL Editor

-- 1. Disable RLS temporarily for admin access
ALTER TABLE public.bookings DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.hotel_submissions DISABLE ROW LEVEL SECURITY;

-- 2. Ensure admin role is set
UPDATE auth.users 
SET raw_user_meta_data = jsonb_set(
  raw_user_meta_data,
  '{role}',
  '"admin"'
)
WHERE email = 'admin@gmail.com';

-- 3. Create hotel_submissions table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.hotel_submissions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  hotel_name TEXT NOT NULL,
  location TEXT NOT NULL,
  description TEXT NOT NULL,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  image_url TEXT,
  contact_phone TEXT NOT NULL,
  contact_email TEXT NOT NULL,
  website TEXT,
  amenities TEXT,
  room_types TEXT,
  price_range TEXT,
  establishment_year TEXT,
  special_features TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  reviewed_by UUID REFERENCES auth.users(id),
  admin_notes TEXT,
  submission_data JSONB
);

-- 4. Add test data to verify it works
INSERT INTO public.hotel_submissions (
  hotel_name, location, description, rating, contact_phone, contact_email
) VALUES (
  'Test Hotel for Admin', 'Kathmandu', 'This is a test hotel to verify admin dashboard works', 4, '+977-1234567890', 'test@hotel.com'
) ON CONFLICT DO NOTHING;

-- 5. Re-enable RLS with simple policies
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hotel_submissions ENABLE ROW LEVEL SECURITY;

-- 6. Drop all existing policies
DROP POLICY IF EXISTS "Users can view own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Admins can view all bookings" ON public.bookings;
DROP POLICY IF EXISTS "Users can insert own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Users can update own bookings" ON public.bookings;

DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;

DROP POLICY IF EXISTS "Anyone can insert hotel submissions" ON public.hotel_submissions;
DROP POLICY IF EXISTS "Admins can read all hotel submissions" ON public.hotel_submissions;
DROP POLICY IF EXISTS "Admins can update hotel submissions" ON public.hotel_submissions;

-- 7. Create simple admin policies
CREATE POLICY "Allow all access for admins" ON public.bookings
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'role' = 'admin'
    )
  );

CREATE POLICY "Allow all access for admins" ON public.profiles
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'role' = 'admin'
    )
  );

CREATE POLICY "Allow all access for admins" ON public.hotel_submissions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'role' = 'admin'
    )
  );

-- 8. Create user policies
CREATE POLICY "Users can manage own bookings" ON public.bookings
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own profile" ON public.profiles
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Anyone can submit hotels" ON public.hotel_submissions
  FOR INSERT WITH CHECK (true);

-- 9. Verify admin user
SELECT 
  'Admin User Check' as info,
  email,
  raw_user_meta_data->>'role' as role
FROM auth.users 
WHERE email = 'admin@gmail.com';

-- 10. Verify test data
SELECT 
  'Test Hotel Submission' as info,
  hotel_name,
  location,
  status
FROM hotel_submissions 
WHERE hotel_name = 'Test Hotel for Admin';
