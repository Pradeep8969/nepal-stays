-- Delete all data of logged-in users
-- WARNING: This will permanently delete all user data including profiles, bookings, and authentication records
-- Run this in Supabase SQL Editor

-- First, let's see what users exist before deletion
SELECT 
    u.id,
    u.email,
    u.created_at,
    u.last_sign_in_at,
    p.full_name,
    p.phone,
    COUNT(b.id) as booking_count
FROM auth.users u
LEFT JOIN public.profiles p ON u.id = p.user_id
LEFT JOIN public.bookings b ON u.id = b.user_id
GROUP BY u.id, u.email, u.created_at, u.last_sign_in_at, p.full_name, p.phone
ORDER BY u.created_at DESC;

-- Delete all bookings for all users
DELETE FROM public.bookings;

-- Delete all user profiles
DELETE FROM public.profiles;

-- Delete all user authentication records
DELETE FROM auth.users;

-- Verify all data has been deleted
SELECT 
    (SELECT COUNT(*) FROM auth.users) as auth_users_count,
    (SELECT COUNT(*) FROM public.profiles) as profiles_count,
    (SELECT COUNT(*) FROM public.bookings) as bookings_count;

-- Note: This will delete ALL user data permanently.
-- If you want to delete only specific users, modify the WHERE clause in the DELETE statements.
