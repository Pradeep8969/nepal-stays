-- Debug booking save issue - booking appears successful but doesn't save
-- Run this in Supabase SQL Editor

-- 1. Check if there's a trigger function interfering with bookings
SELECT 
  'Trigger Functions Check' as info,
  routine_name,
  routine_type,
  action_timing,
  action_condition,
  action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'bookings';

-- 2. Check if there are any constraints on bookings table
SELECT 
  'Constraints Check' as info,
  constraint_name,
  constraint_type,
  table_name,
  column_name,
  check_clause
FROM information_schema.check_constraints 
WHERE table_name = 'bookings';

-- 3. Check bookings table structure
SELECT 
  'Bookings Table Structure' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'bookings'
ORDER BY ordinal_position;

-- 4. Try a simple manual insert to test
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
  'test-hotel-id',
  'test-user-id',
  '2026-04-10',
  '2026-04-12',
  2,
  'Standard',
  '+977-1234567890',
  200.00,
  'confirmed',
  NOW()
);

-- 5. Check if the test insert worked
SELECT 
  'Test Insert Verification' as info,
  COUNT(*) as test_bookings
FROM public.bookings 
WHERE user_id = 'test-user-id';

-- 6. Check RLS policies are working correctly
SELECT 
  'RLS Policies Check' as info,
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

-- 7. Disable RLS temporarily to test if that's the issue
ALTER TABLE public.bookings DISABLE ROW LEVEL SECURITY;

-- 8. Try another test insert with RLS disabled
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
  'test-hotel-id-2',
  'test-user-id-2',
  '2026-04-11',
  '2026-04-13',
  3,
  'Deluxe',
  '+977-1234567891',
  300.00,
  'confirmed',
  NOW()
);

-- 9. Check if second test insert worked
SELECT 
  'Test Insert 2 Verification' as info,
  COUNT(*) as test_bookings_2
FROM public.bookings 
WHERE user_id = 'test-user-id-2';

-- 10. Clean up test data
DELETE FROM public.bookings 
WHERE user_id IN ('test-user-id', 'test-user-id-2');

-- 11. Re-enable RLS with simple policy
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Admins can view all bookings" ON public.bookings;

CREATE POLICY "Users can manage own bookings" ON public.bookings
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all bookings" ON public.bookings
  FOR SELECT USING (
    auth.uid() IN (
      SELECT id FROM auth.users 
      WHERE raw_user_meta_data->>'role' = 'admin'
    )
  );

-- 12. Final verification
SELECT 
  'Final State Check' as info,
  COUNT(*) as total_bookings
FROM public.bookings;
