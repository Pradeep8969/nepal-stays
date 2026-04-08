-- Final RLS fix - avoid system table column errors
-- Run this in Supabase SQL Editor

-- 1. Disable RLS temporarily on all tables
ALTER TABLE public.bookings DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.hotels DISABLE ROW LEVEL SECURITY;

-- 2. Drop all existing policies that might be causing conflicts
DROP POLICY IF EXISTS "Users can manage own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Admins can view all bookings" ON public.bookings;
DROP POLICY IF EXISTS "Allow booking inserts" ON public.bookings;
DROP POLICY IF EXISTS "Users can manage own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Public can read hotels" ON public.hotels;

-- 3. Re-enable RLS with simple, working policies
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hotels ENABLE ROW LEVEL SECURITY;

-- 4. Create simple policies for bookings
CREATE POLICY "Users can manage own bookings" ON public.bookings
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all bookings" ON public.bookings
  FOR SELECT USING (
    auth.uid() IN (
      SELECT id FROM auth.users 
      WHERE raw_user_meta_data->>'role' = 'admin'
    )
  );

-- 5. Create simple policies for profiles
CREATE POLICY "Users can manage own profile" ON public.profiles
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all profiles" ON public.profiles
  FOR SELECT USING (
    auth.uid() IN (
      SELECT id FROM auth.users 
      WHERE raw_user_meta_data->>'role' = 'admin'
    )
  );

-- 6. Create simple policies for hotels (public read access)
CREATE POLICY "Public can read hotels" ON public.hotels
  FOR SELECT USING (true);

-- 7. Test the specific user ID from console logs
DO $$
DECLARE
  test_user_id UUID := '70a7bc52-5385-4fea-b9f6-653d0e1ede67';
  booking_count INTEGER;
  profile_count INTEGER;
BEGIN
  -- Test bookings access
  SELECT COUNT(*) INTO booking_count
  FROM public.bookings 
  WHERE user_id = test_user_id;
  
  -- Test profiles access
  SELECT COUNT(*) INTO profile_count
  FROM public.profiles 
  WHERE user_id = test_user_id;
  
  RAISE NOTICE 'Test Results for user %:', test_user_id;
  RAISE NOTICE 'Bookings accessible: %', booking_count;
  RAISE NOTICE 'Profiles accessible: %', profile_count;
END $$;

-- 8. Verify final policies are working
SELECT 
  'Final RLS Policies' as info,
  schemaname,
  tablename,
  policyname,
  permissive,
  cmd
FROM pg_policies 
WHERE tablename IN ('bookings', 'profiles', 'hotels')
ORDER BY tablename, policyname;

-- 9. Test a simple booking insert to verify everything works
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
  
  -- Use the specific user ID from console logs
  user_uuid := '70a7bc52-5385-4fea-b9f6-653d0e1ede67';
  
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
  
  -- Check if booking was successful
  SELECT COUNT(*) > 0 INTO booking_success
  FROM public.bookings 
  WHERE user_id = user_uuid
  AND created_at >= NOW() - INTERVAL '1 minute';
  
  RAISE NOTICE 'Test booking insert: %', CASE 
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
