-- Ultimate booking fix - avoid all information_schema queries
-- Run this in Supabase SQL Editor

-- 1. Check current bookings count
SELECT 
  'Current Bookings Count' as info,
  COUNT(*) as total_bookings
FROM public.bookings;

-- 2. Disable RLS temporarily
ALTER TABLE public.bookings DISABLE ROW LEVEL SECURITY;

-- 3. Drop all existing policies
DROP POLICY IF EXISTS "Users can manage own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Admins can view all bookings" ON public.bookings;
DROP POLICY IF EXISTS "Allow booking inserts" ON public.bookings;

-- 4. Test booking insert with RLS disabled
DO $$
DECLARE
  hotel_id UUID;
  booking_result BOOLEAN;
BEGIN
  -- Get first available hotel ID
  SELECT id INTO hotel_id 
  FROM public.hotels 
  LIMIT 1;
  
  -- Try to insert booking
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
    auth.uid(),
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
  WHERE user_id = auth.uid()
  AND created_at >= NOW() - INTERVAL '1 minute';
  
  RAISE NOTICE 'Test with RLS disabled: %', CASE 
    WHEN booking_result THEN 'SUCCESS'
    ELSE 'FAILED'
  END;
  
  -- Clean up test booking
  IF booking_result THEN
    DELETE FROM public.bookings 
    WHERE user_id = auth.uid()
    AND created_at >= NOW() - INTERVAL '1 minute';
  END IF;
END $$;

-- 5. Re-enable RLS with simple policies
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- 6. Create simple user policy
CREATE POLICY "Users can manage own bookings" ON public.bookings
  FOR ALL USING (auth.uid() = user_id);

-- 7. Create simple admin policy
CREATE POLICY "Admins can view all bookings" ON public.bookings
  FOR SELECT USING (
    auth.uid() IN (
      SELECT id FROM auth.users 
      WHERE raw_user_meta_data->>'role' = 'admin'
    )
  );

-- 8. Test booking with RLS enabled
DO $$
DECLARE
  hotel_id UUID;
  booking_result BOOLEAN;
BEGIN
  -- Get first available hotel ID
  SELECT id INTO hotel_id 
  FROM public.hotels 
  LIMIT 1;
  
  -- Try to insert booking
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
    auth.uid(),
    '2026-04-11',
    '2026-04-13',
    3,
    'Deluxe',
    '+977-1234567891',
    300.00,
    'confirmed',
    NOW()
  );
  
  -- Check if booking was successful
  SELECT COUNT(*) > 0 INTO booking_result
  FROM public.bookings 
  WHERE user_id = auth.uid()
  AND created_at >= NOW() - INTERVAL '1 minute';
  
  RAISE NOTICE 'Test with RLS enabled: %', CASE 
    WHEN booking_result THEN 'SUCCESS'
    ELSE 'FAILED'
  END;
  
  -- Clean up test booking
  IF booking_result THEN
    DELETE FROM public.bookings 
    WHERE user_id = auth.uid()
    AND created_at >= NOW() - INTERVAL '1 minute';
  END IF;
END $$;

-- 9. Final verification
SELECT 
  'Final Verification' as info,
  COUNT(*) as total_bookings_after_fix
FROM public.bookings;

-- 10. Show available hotels
SELECT 
  'Available Hotels' as info,
  id,
  name,
  location
FROM public.hotels 
ORDER BY name
LIMIT 3;
