-- Fix admin dashboard issues
-- Run this in Supabase SQL Editor

-- 1. Ensure hotel_submissions table exists with proper policies
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

-- Enable RLS
ALTER TABLE public.hotel_submissions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can insert hotel submissions" ON public.hotel_submissions;
DROP POLICY IF EXISTS "Admins can read all hotel submissions" ON public.hotel_submissions;
DROP POLICY IF EXISTS "Admins can update hotel submissions" ON public.hotel_submissions;

-- Create proper policies
CREATE POLICY "Anyone can insert hotel submissions" ON public.hotel_submissions
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can read all hotel submissions" ON public.hotel_submissions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'role' = 'admin'
    )
  );

CREATE POLICY "Admins can update hotel submissions" ON public.hotel_submissions
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'role' = 'admin'
    )
  );

-- 2. Fix profiles table RLS for admin access
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;

CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all profiles" ON public.profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'role' = 'admin'
    )
  );

CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 3. Fix bookings table RLS for admin access
DROP POLICY IF EXISTS "Users can view own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Users can insert own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Users can update own bookings" ON public.bookings;

CREATE POLICY "Users can view own bookings" ON public.bookings
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all bookings" ON public.bookings
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'role' = 'admin'
    )
  );

CREATE POLICY "Users can insert own bookings" ON public.bookings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own bookings" ON public.bookings
  FOR UPDATE USING (auth.uid() = user_id);

-- 4. Ensure admin role is properly set
UPDATE auth.users 
SET raw_user_meta_data = jsonb_set(
  raw_user_meta_data,
  '{role}',
  '"admin"'
)
WHERE email = 'admin@gmail.com';

-- 5. Test data (optional - uncomment if you want sample data)
/*
INSERT INTO public.hotel_submissions (
  hotel_name, location, description, rating, contact_phone, contact_email
) VALUES (
  'Test Hotel', 'Kathmandu', 'A beautiful test hotel', 4, '+977-1234567890', 'test@example.com'
);
*/
