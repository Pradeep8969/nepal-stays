-- Fix booking display issue - booking created but not showing
-- Run this in Supabase SQL Editor

-- 1. First, let's check what's actually in the bookings table
SELECT 
  'Current Bookings in Database' as info,
  COUNT(*) as total_bookings,
  MIN(created_at) as earliest_booking,
  MAX(created_at) as latest_booking
FROM public.bookings;

-- 2. Check if there are any recent bookings
SELECT 
  'Recent Bookings (last 24 hours)' as info,
  id,
  user_id,
  hotel_id,
  check_in_date,
  check_out_date,
  guests,
  total_price,
  status,
  created_at
FROM public.bookings 
WHERE created_at >= NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;

-- 3. Check if profiles table has matching records
SELECT 
  'Profiles Table Check' as info,
  COUNT(*) as total_profiles,
  COUNT(CASE WHEN full_name IS NOT NULL THEN 1 END) as profiles_with_names
FROM public.profiles;

-- 4. Check the specific join that admin dashboard uses
SELECT 
  'Admin Dashboard Join Test' as info,
  b.id,
  b.user_id,
  b.hotel_id,
  b.total_price,
  b.created_at,
  h.name as hotel_name,
  p.full_name,
  p.email
FROM public.bookings b
LEFT JOIN public.hotels h ON b.hotel_id = h.id
LEFT JOIN public.profiles p ON b.user_id = p.user_id
ORDER BY b.created_at DESC
LIMIT 5;

-- 5. Fix the profiles table policies - ensure users can see their own profiles
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own profile" ON public.profiles
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all profiles" ON public.profiles
  FOR SELECT USING (
    auth.uid() IN (
      SELECT id FROM auth.users 
      WHERE raw_user_meta_data->>'role' = 'admin'
    )
  );

-- 6. Fix bookings table policies - ensure proper access
ALTER TABLE public.bookings DISABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Admins can view all bookings" ON public.bookings;

ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own bookings" ON public.bookings
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all bookings" ON public.bookings
  FOR SELECT USING (
    auth.uid() IN (
      SELECT id FROM auth.users 
      WHERE raw_user_meta_data->>'role' = 'admin'
    )
  );

-- 7. Ensure user has a profile record
INSERT INTO public.profiles (user_id, full_name, email, created_at)
SELECT 
  id,
  COALESCE(raw_user_meta_data->>'full_name', 'User') as full_name,
  email,
  NOW()
FROM auth.users 
WHERE email NOT IN (SELECT email FROM public.profiles)
AND email IS NOT NULL
ON CONFLICT (user_id) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  email = EXCLUDED.email;

-- 8. Verify the fixes
SELECT 
  'Fix Verification - Bookings Count' as info,
  COUNT(*) as count
FROM public.bookings;

SELECT 
  'Fix Verification - Profiles Count' as info,
  COUNT(*) as count
FROM public.profiles;

SELECT 
  'Fix Verification - Admin Role' as info,
  email,
  raw_user_meta_data->>'role' as role
FROM auth.users 
WHERE email = 'admin@gmail.com';
