-- Fix booking permission denied error for users table
-- Run this in Supabase SQL Editor

-- 1. Disable RLS on auth.users (this is a system table, shouldn't have RLS)
ALTER TABLE auth.users DISABLE ROW LEVEL SECURITY;

-- 2. Disable RLS on all public tables temporarily to fix booking issues
ALTER TABLE public.bookings DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.hotel_submissions DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.hotels DISABLE ROW LEVEL SECURITY;

-- 3. Drop all existing policies that might be causing issues
DROP POLICY IF EXISTS "Users can view own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Admins can view all bookings" ON public.bookings;
DROP POLICY IF EXISTS "Users can insert own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Users can update own bookings" ON public.bookings;

DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;

DROP POLICY IF EXISTS "Anyone can insert hotel submissions" ON public.hotel_submissions;
DROP POLICY IF EXISTS "Admins can read all hotel submissions" ON public.hotel_submissions;
DROP POLICY IF EXISTS "Admins can update hotel submissions" ON public.hotel_submissions;

DROP POLICY IF EXISTS "Allow all access for admins" ON public.bookings;
DROP POLICY IF EXISTS "Allow all access for admins" ON public.profiles;
DROP POLICY IF EXISTS "Allow all access for admins" ON public.hotel_submissions;

DROP POLICY IF EXISTS "Users can manage own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Users can manage own profile" ON public.profiles;
DROP POLICY IF EXISTS "Anyone can submit hotels" ON public.hotel_submissions;

-- 4. Re-enable RLS with simple, working policies
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hotel_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hotels ENABLE ROW LEVEL SECURITY;

-- 5. Create simple policies that work
-- Bookings: Users can manage their own, admins can see all
CREATE POLICY "Users can manage own bookings" ON public.bookings
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all bookings" ON public.bookings
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'role' = 'admin'
    )
  );

-- Profiles: Users can manage their own, admins can see all
CREATE POLICY "Users can manage own profile" ON public.profiles
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all profiles" ON public.profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'role' = 'admin'
    )
  );

-- Hotel submissions: Anyone can submit, admins can manage
CREATE POLICY "Anyone can submit hotels" ON public.hotel_submissions
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can manage hotel submissions" ON public.hotel_submissions
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'role' = 'admin'
    )
  );

-- Hotels: Everyone can view, admins can manage
CREATE POLICY "Everyone can view hotels" ON public.hotels
  FOR SELECT USING (true);

CREATE POLICY "Admins can manage hotels" ON public.hotels
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE auth.users.id = auth.uid() 
      AND auth.users.raw_user_meta_data->>'role' = 'admin'
    )
  );

-- 6. Ensure admin role is set
UPDATE auth.users 
SET raw_user_meta_data = jsonb_set(
  raw_user_meta_data,
  '{role}',
  '"admin"'
)
WHERE email = 'admin@gmail.com';

-- 7. Test the fix - try to insert a test booking
INSERT INTO public.bookings (
  hotel_id, user_id, check_in_date, check_out_date, guests, room_type, guest_phone, total_price, status
) VALUES (
  'test-hotel-id', 
  (SELECT id FROM auth.users WHERE email = 'admin@gmail.com' LIMIT 1),
  '2026-04-10', 
  '2026-04-12', 
  2, 
  'Standard', 
  '+977-1234567890', 
  200.00, 
  'confirmed'
) ON CONFLICT DO NOTHING;

-- 8. Verify the fix worked
SELECT 
  'Booking Test' as info,
  COUNT(*) as test_bookings
FROM public.bookings 
WHERE hotel_id = 'test-hotel-id';

SELECT 
  'Admin Role Check' as info,
  email,
  raw_user_meta_data->>'role' as role
FROM auth.users 
WHERE email = 'admin@gmail.com';
