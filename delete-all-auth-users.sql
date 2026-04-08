-- Delete all authenticated users from database
-- WARNING: This will permanently delete all user accounts including admin
-- Run this in Supabase SQL Editor

-- 1. First clear all user data (profiles, bookings, submissions)
DELETE FROM public.bookings;
DELETE FROM public.profiles;
DELETE FROM public.hotel_submissions;

-- 2. Delete all authenticated users from auth.users table
-- This includes admin account and all other users
DELETE FROM auth.users;

-- 3. Verification - show counts after deletion
SELECT 
  'Auth users after deletion' as info,
  COUNT(*) as count
FROM auth.users;

SELECT 
  'Profiles after deletion' as info,
  COUNT(*) as count
FROM public.profiles;

SELECT 
  'Bookings after deletion' as info,
  COUNT(*) as count
FROM public.bookings;

SELECT 
  'Hotel submissions after deletion' as info,
  COUNT(*) as count
FROM public.hotel_submissions;

SELECT 
  'Hotels remaining' as info,
  COUNT(*) as count
FROM public.hotels;

-- 4. Final confirmation
SELECT 
  'Complete reset done' as status,
  'All users and data deleted - you will need to recreate admin account' as message;

-- NOTE: After running this, you'll need to:
-- 1. Create a new admin account through signup
-- 2. Manually set admin role in auth.users.raw_user_meta_data
-- 3. Or use the admin creation script again
