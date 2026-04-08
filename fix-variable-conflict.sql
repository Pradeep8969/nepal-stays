-- Fix variable naming conflict in booking test
-- Run this in Supabase SQL Editor

-- 1. Check authentication status
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

-- 3. Get available users
SELECT 
  'Available Users' as info,
  id,
  email,
  created_at
FROM auth.users 
ORDER BY created_at DESC
LIMIT 3;

-- 4. Get available hotels
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

-- 6. Drop existing policies
DROP POLICY IF EXISTS "Users can manage own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Admins can view all bookings" ON public.bookings;

-- 7. Test booking with fixed variable names
DO $$
DECLARE
  hotel_uuid UUID;
  user_uuid UUID;
  booking_success BOOLEAN;
BEGIN
  -- Get first available hotel ID
  SELECT id INTO hotel_uuid 
  FROM public.hotels 
  LIMIT 1;
  
  -- Get first available user ID
  SELECT id INTO user_uuid 
  FROM auth.users 
  LIMIT 1;
  
  -- Try to insert booking with fixed variable names
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
    user_uuid,
    '2026-04-10',
    '2026-04-12',
    2,
    'Standard',
    '+977-1234567890',
    200.00,
    'confirmed',
    NOW()
  );
  
  -- Check if booking was successful (fixed variable conflict)
  SELECT COUNT(*) > 0 INTO booking_success
  FROM public.bookings 
  WHERE user_id = user_uuid
  AND created_at >= NOW() - INTERVAL '1 minute';
  
  RAISE NOTICE 'Test with fixed variables: %', CASE 
    WHEN booking_success THEN 'SUCCESS'
    ELSE 'FAILED'
  END;
  
  -- Clean up test booking
  IF booking_success THEN
    DELETE FROM public.bookings 
    WHERE user_id = user_uuid
    AND created_at >= NOW() - INTERVAL '1 minute';
  END IF;
END $$;

-- 8. Re-enable RLS with proper policies
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- 9. Create user policy
CREATE POLICY "Users can manage own bookings" ON public.bookings
  FOR ALL USING (auth.uid() = user_id);

-- 10. Create admin policy
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
