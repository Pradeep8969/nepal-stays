-- Fix booking constraint violation - user_id cannot be null
-- Run this in Supabase SQL Editor

-- 1. First, let's check the bookings table structure
SELECT 
  'Bookings Table Structure' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'bookings'
ORDER BY ordinal_position;

-- 2. Check if there are any constraints on user_id
SELECT 
  'User ID Constraints' as info,
  constraint_name,
  constraint_type,
  check_clause
FROM information_schema.check_constraints 
WHERE table_name = 'bookings'
AND column_name = 'user_id';

-- 3. Check current RLS policies
SELECT 
  'Current RLS Policies' as info,
  policyname,
  permissive,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'bookings';

-- 4. Temporarily disable RLS to fix constraint issue
ALTER TABLE public.bookings DISABLE ROW LEVEL SECURITY;

-- 5. Drop existing policies that might be causing issues
DROP POLICY IF EXISTS "Users can manage own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Admins can view all bookings" ON public.bookings;

-- 6. Create a simple policy that allows inserts
CREATE POLICY "Allow booking inserts" ON public.bookings
  FOR INSERT WITH CHECK (true);

-- 7. Re-enable RLS with working policies
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- 8. Create proper policies for users and admins
CREATE POLICY "Users can manage own bookings" ON public.bookings
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all bookings" ON public.bookings
  FOR SELECT USING (
    auth.uid() IN (
      SELECT id FROM auth.users 
      WHERE raw_user_meta_data->>'role' = 'admin'
    )
  );

-- 9. Test the booking insert again
DO $$
DECLARE
  hotel_id UUID;
  booking_result BOOLEAN;
BEGIN
  -- Get first available hotel ID
  SELECT id INTO hotel_id 
  FROM public.hotels 
  LIMIT 1;
  
  -- Try to insert booking with that hotel ID
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
  
  RAISE NOTICE '✅ Booking test result: %', CASE 
    WHEN booking_result THEN 'SUCCESS'
    ELSE 'FAILED'
  END;
END $$;

-- 10. Final verification
SELECT 
  'Final Verification' as info,
  COUNT(*) as total_bookings
FROM public.bookings;
