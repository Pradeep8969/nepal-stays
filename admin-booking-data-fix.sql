-- Admin booking data fix - check and fix booking data visibility
-- Run this in Supabase SQL Editor

-- 1. Check if bookings table has any data
SELECT 
  'All bookings in database' as info,
  COUNT(*) as total_bookings
FROM public.bookings;

-- 2. Show sample booking data to understand structure
SELECT 
  'Sample booking data' as info,
  id,
  hotel_id,
  user_id,
  check_in_date,
  check_out_date,
  guests,
  room_type,
  guest_phone,
  total_price,
  status,
  created_at
FROM public.bookings 
ORDER BY created_at DESC
LIMIT 5;

-- 3. Check if the specific user has bookings
SELECT 
  'Bookings for specific user' as info,
  COUNT(*) as user_bookings_count
FROM public.bookings 
WHERE user_id = '70a7bc52-5385-4fea-b9f6-653d0e1ede67';

-- 4. Show bookings for the specific user
SELECT 
  'User bookings details' as info,
  id,
  hotel_id,
  user_id,
  check_in_date,
  check_out_date,
  guests,
  room_type,
  guest_phone,
  total_price,
  status,
  created_at
FROM public.bookings 
WHERE user_id = '70a7bc52-5385-4fea-b9f6-653d0e1ede67'
ORDER BY created_at DESC;

-- 5. Check if hotels table has data for joining
SELECT 
  'Hotels table check' as info,
  COUNT(*) as total_hotels
FROM public.hotels;

-- 6. Show sample hotel data
SELECT 
  'Sample hotel data' as info,
  id,
  name,
  location,
  image_url
FROM public.hotels 
LIMIT 3;

-- 7. Test the exact query the admin dashboard is using
SELECT 
  b.id,
  b.check_in_date,
  b.check_out_date,
  b.guests,
  b.room_type,
  b.total_price,
  b.status,
  b.created_at,
  b.guest_phone,
  h.name,
  h.location,
  h.image_url,
  p.full_name,
  p.email
FROM public.bookings b
LEFT JOIN public.hotels h ON b.hotel_id = h.id
LEFT JOIN public.profiles p ON b.user_id = p.user_id
ORDER BY b.created_at DESC
LIMIT 10;

-- 8. Test a simpler booking query for admin
SELECT 
  'Simple admin booking query' as info,
  b.id,
  b.hotel_id,
  b.user_id,
  b.check_in_date,
  b.check_out_date,
  b.status,
  b.created_at,
  h.name as hotel_name,
  p.full_name as user_name
FROM public.bookings b
LEFT JOIN public.hotels h ON b.hotel_id = h.id
LEFT JOIN public.profiles p ON b.user_id = p.user_id
ORDER BY b.created_at DESC;

-- 9. If no bookings exist, create a test booking
DO $$
DECLARE
  hotel_uuid UUID;
  booking_exists BOOLEAN;
BEGIN
  -- Check if any bookings exist
  SELECT EXISTS(SELECT 1 FROM public.bookings) INTO booking_exists;
  
  IF NOT booking_exists THEN
    -- Get first available hotel ID
    SELECT id INTO hotel_uuid 
    FROM public.hotels 
    LIMIT 1;
    
    IF hotel_uuid IS NOT NULL THEN
      -- Create test booking
      INSERT INTO public.bookings (
        hotel_id,
        user_id,
        check_in_date,
        check_out_date,
        guests,
        room_type,
        guest_phone,
        total_price,
        status,
        created_at
      ) VALUES (
        hotel_uuid,
        '70a7bc52-5385-4fea-b9f6-653d0e1ede67',
        '2026-04-10',
        '2026-04-12',
        2,
        'Standard',
        '+977-1234567890',
        200.00,
        'confirmed',
        NOW()
      );
      
      RAISE NOTICE 'Created test booking for admin dashboard testing';
    ELSE
      RAISE NOTICE 'No hotels found to create test booking';
    END IF;
  END IF;
END $$;

-- 10. Final verification - check booking count again
SELECT 
  'Final booking count' as info,
  COUNT(*) as total_bookings,
  (SELECT COUNT(*) FROM public.bookings WHERE user_id = '70a7bc52-5385-4fea-b9f6-653d0e1ede67') as user_bookings
FROM public.bookings;

-- 11. Admin dashboard query test
SELECT 
  'Admin dashboard ready' as info,
  CASE 
    WHEN COUNT(*) > 0 THEN 'Bookings available for admin dashboard'
    ELSE 'No bookings found - test booking created'
  END as status
FROM public.bookings;
