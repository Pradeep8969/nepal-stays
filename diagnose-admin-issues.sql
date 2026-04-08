-- Diagnostic script to check admin dashboard issues
-- Run this in Supabase SQL Editor to see what's happening

-- 1. Check if admin user exists and has proper role
SELECT 
  id,
  email,
  raw_user_meta_data,
  raw_user_meta_data->>'role' as admin_role
FROM auth.users 
WHERE email = 'admin@gmail.com';

-- 2. Check if hotel_submissions table exists
SELECT 
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'hotel_submissions' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Check RLS policies for hotel_submissions
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'hotel_submissions';

-- 4. Check existing hotel submissions
SELECT 
  id,
  hotel_name,
  location,
  status,
  submitted_at
FROM hotel_submissions 
ORDER BY submitted_at DESC 
LIMIT 5;

-- 5. Check if there are any bookings
SELECT 
  COUNT(*) as total_bookings,
  MIN(created_at) as earliest_booking,
  MAX(created_at) as latest_booking
FROM bookings;

-- 6. Check sample booking data with joins
SELECT 
  b.id,
  b.user_id,
  b.created_at,
  b.total_price,
  h.name as hotel_name,
  p.full_name,
  p.email
FROM bookings b
LEFT JOIN hotels h ON b.hotel_id = h.id
LEFT JOIN profiles p ON b.user_id = p.user_id
LIMIT 3;

-- 7. Check RLS policies for bookings table
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'bookings';

-- 8. Check RLS policies for profiles table
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'profiles';

-- 9. Test admin access by trying to count submissions
SELECT 
  COUNT(*) as submission_count
FROM hotel_submissions;

-- 10. Test admin access by trying to count bookings
SELECT 
  COUNT(*) as booking_count
FROM bookings;
