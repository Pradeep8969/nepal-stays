-- Fix authentication booking issue - auth.uid() returns NULL
-- Run this in Supabase SQL Editor

-- 1. First, let's check if we're authenticated
SELECT 
  'Authentication Check' as info,
  auth.uid() as current_user_id,
  auth.email() as current_email,
  auth.role() as current_role;

-- 2. Check current bookings count
SELECT 
  'Current Bookings Count' as info,
  COUNT(*) as total_bookings
FROM public.bookings;

-- 3. Get a real user ID from the database
SELECT 
  'Available Users' as info,
  id,
  email,
  created_at
FROM auth.users 
ORDER BY created_at DESC
LIMIT 3;

-- 4. Get a real hotel ID
SELECT 
  'Available Hotels' as info,
  id,
  name,
  location
FROM public.hotels 
ORDER BY name
LIMIT 3;

-- 5. Disable RLS temporarily
ALTER TABLE public.bookings DISABLE ROW LEVEL SECURITY;

-- 6. Drop all existing policies
DROP POLICY IF EXISTS "Users can manage own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Admins can view all bookings" ON public.bookings;

-- 7. Test booking with hardcoded user ID (replace with actual user ID from step 3)
DO $$
DECLARE
  hotel_id UUID;
  user_id UUID;
  booking_result BOOLEAN;
BEGIN
  -- Get first available hotel ID
  SELECT id INTO hotel_id 
  FROM public.hotels 
  LIMIT 1;
  
  -- Use first available user ID (replace with actual user ID from step 3)
  SELECT id INTO user_id 
  FROM auth.users 
  LIMIT 1;
  
  -- Try to insert booking with hardcoded user ID
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
    hotel_id,
    user_id,  -- Use hardcoded user ID instead of auth.uid()
    '2026-04-10',
    '2026-04-12',
    2,
    'Standard',
    '+977-1234567890',
    200.00,
    'confirmed',
    NOW()
  );
  
  -- Check if booking was successful
  SELECT COUNT(*) > 0 INTO booking_result
  FROM public.bookings 
  WHERE user_id = user_id
  AND created_at >= NOW() - INTERVAL '1 minute';
  
  RAISE NOTICE 'Test with hardcoded user ID: %', CASE 
    WHEN booking_result THEN 'SUCCESS'
    ELSE 'FAILED'
  END;
  
  -- Clean up test booking
  IF booking_result THEN
    DELETE FROM public.bookings 
    WHERE user_id = user_id
    AND created_at >= NOW() - INTERVAL '1 minute';
  END IF;
END $$;

-- 8. Re-enable RLS with proper policies
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- 9. Create simple user policy
CREATE POLICY "Users can manage own bookings" ON public.bookings
  FOR ALL USING (auth.uid() = user_id);

-- 10. Create simple admin policy
CREATE POLICY "Admins can view all bookings" ON public.bookings
  FOR SELECT USING (
    auth.uid() IN (
      SELECT id FROM auth.users 
      WHERE raw_user_meta_data->>'role' = 'admin'
    )
  );

-- 11. Final verification
SELECT 
  'Final Verification' as info,
  COUNT(*) as total_bookings_after_fix
FROM public.bookings;
