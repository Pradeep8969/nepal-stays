-- Simple booking fix - avoid modifying auth.users table
-- Run this in Supabase SQL Editor

-- 1. Disable RLS on all public tables temporarily
ALTER TABLE public.bookings DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.hotel_submissions DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.hotels DISABLE ROW LEVEL SECURITY;

-- 2. Drop all existing policies that might be causing issues
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

DROP POLICY IF EXISTS "Allow all access for admins" ON public.bookings;
DROP POLICY IF EXISTS "Allow all access for admins" ON public.profiles;
DROP POLICY IF EXISTS "Allow all access for admins" ON public.hotel_submissions;

DROP POLICY IF EXISTS "Users can manage own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Users can manage own profile" ON public.profiles;
DROP POLICY IF EXISTS "Anyone can submit hotels" ON public.hotel_submissions;

-- 3. Re-enable RLS with simple, working policies
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hotel_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hotels ENABLE ROW LEVEL SECURITY;

-- 4. Create simple policies that work
-- Bookings: Users can manage their own, admins can see all
CREATE POLICY "Users can manage own bookings" ON public.bookings
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all bookings" ON public.bookings
  FOR SELECT USING (
    auth.uid() IN (
      SELECT id FROM auth.users 
      WHERE raw_user_meta_data->>'role' = 'admin'
    )
  );

-- Profiles: Users can manage their own, admins can see all
CREATE POLICY "Users can manage own profile" ON public.profiles
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all profiles" ON public.profiles
  FOR SELECT USING (
    auth.uid() IN (
      SELECT id FROM auth.users 
      WHERE raw_user_meta_data->>'role' = 'admin'
    )
  );

-- Hotel submissions: Anyone can submit, admins can manage
CREATE POLICY "Anyone can submit hotels" ON public.hotel_submissions
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can manage hotel submissions" ON public.hotel_submissions
  FOR ALL USING (
    auth.uid() IN (
      SELECT id FROM auth.users 
      WHERE raw_user_meta_data->>'role' = 'admin'
    )
  );

-- Hotels: Everyone can view, admins can manage
CREATE POLICY "Everyone can view hotels" ON public.hotels
  FOR SELECT USING (true);

CREATE POLICY "Admins can manage hotels" ON public.hotels
  FOR ALL USING (
    auth.uid() IN (
      SELECT id FROM auth.users 
      WHERE raw_user_meta_data->>'role' = 'admin'
    )
  );

-- 5. Ensure admin role is set (this should work)
UPDATE auth.users 
SET raw_user_meta_data = jsonb_set(
  raw_user_meta_data,
  '{role}',
  '"admin"'
)
WHERE email = 'admin@gmail.com';

-- 6. Create hotel_submissions table if it doesn't exist
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

-- 7. Add test data to verify it works
INSERT INTO public.hotel_submissions (
  hotel_name, location, description, rating, contact_phone, contact_email
) VALUES (
  'Test Hotel for Admin', 'Kathmandu', 'This is a test hotel to verify admin dashboard works', 4, '+977-1234567890', 'test@hotel.com'
) ON CONFLICT DO NOTHING;

-- 8. Verify the fix worked
SELECT 
  'Admin Role Check' as info,
  email,
  raw_user_meta_data->>'role' as role
FROM auth.users 
WHERE email = 'admin@gmail.com';

SELECT 
  'Hotel Submissions Count' as info,
  COUNT(*) as count
FROM public.hotel_submissions;

SELECT 
  'Bookings Count' as info,
  COUNT(*) as count
FROM public.bookings;
