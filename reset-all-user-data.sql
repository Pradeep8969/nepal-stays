-- Reset all user data - complete fresh start
-- Run this in Supabase SQL Editor to clear all user data

-- 1. Clear all bookings
DELETE FROM public.bookings;

-- 2. Clear all user profiles
DELETE FROM public.profiles;

-- 3. Clear all hotel submissions
DELETE FROM public.hotel_submissions;

-- 4. Clear all hotels (optional - only if you want to reset hotels too)
-- DELETE FROM public.hotels;

-- 5. Reset auto-increment sequences (if applicable)
-- ALTER SEQUENCE public.bookings_id_seq RESTART WITH 1;
-- ALTER SEQUENCE public.profiles_user_id_seq RESTART WITH 1;

-- 6. Verification - show counts after deletion
SELECT 
  'Bookings after reset' as info,
  COUNT(*) as count
FROM public.bookings;

SELECT 
  'Profiles after reset' as info,
  COUNT(*) as count
FROM public.profiles;

SELECT 
  'Hotel submissions after reset' as info,
  COUNT(*) as count
FROM public.hotel_submissions;

SELECT 
  'Hotels remaining' as info,
  COUNT(*) as count
FROM public.hotels;

-- 7. Final confirmation
SELECT 
  'Reset complete' as status,
  'All user data cleared - ready for fresh start' as message;
