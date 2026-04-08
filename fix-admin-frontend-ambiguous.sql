-- Fix admin frontend query - resolve ambiguous column reference
-- Run this in Supabase SQL Editor

-- 1. Check actual profiles table schema
SELECT 
  'Profiles table schema' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'profiles'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Check actual hotels table schema
SELECT 
  'Hotels table schema' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'hotels'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Check actual bookings table schema
SELECT 
  'Bookings table schema' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'bookings'
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. Test the exact frontend query that's failing
SELECT 
  'Test frontend query' as info,
  b.*,
  h.name,
  h.location,
  h.image_url,
  p.full_name,
  p.email
FROM public.bookings b
LEFT JOIN public.hotels h ON b.hotel_id = h.id
LEFT JOIN public.profiles p ON b.user_id = p.user_id
ORDER BY b.created_at DESC
LIMIT 1;

-- 5. Test simplified query without profiles join
SELECT 
  'Test simplified query (no profiles)' as info,
  b.*,
  h.name,
  h.location,
  h.image_url
FROM public.bookings b
LEFT JOIN public.hotels h ON b.hotel_id = h.id
ORDER BY b.created_at DESC
LIMIT 1;

-- 6. Test with only basic columns
SELECT 
  'Test basic columns only' as info,
  b.id,
  b.hotel_id,
  b.user_id,
  b.check_in_date,
  b.check_out_date,
  b.guests,
  b.room_type,
  b.total_price,
  b.status,
  b.created_at,
  h.name,
  h.location,
  h.image_url
FROM public.bookings b
LEFT JOIN public.hotels h ON b.hotel_id = h.id
ORDER BY b.created_at DESC
LIMIT 1;

-- 7. Add missing columns to profiles if they don't exist
DO $$
BEGIN
  -- Check and add full_name column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' 
    AND column_name = 'full_name'
    AND table_schema = 'public'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN full_name TEXT;
    RAISE NOTICE 'Added full_name column to profiles table';
  END IF;
  
  -- Check and add email column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' 
    AND column_name = 'email'
    AND table_schema = 'public'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN email TEXT;
    RAISE NOTICE 'Added email column to profiles table';
  END IF;
  
  -- Check and add phone column if missing
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' 
    AND column_name = 'phone'
    AND table_schema = 'public'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN phone TEXT;
    RAISE NOTICE 'Added phone column to profiles table';
  END IF;
END $$;

-- 8. Update existing profiles with missing data (fixed ambiguous reference)
DO $$
BEGIN
  -- Update profiles with user data from auth.users - fixed ambiguous column reference
  UPDATE public.profiles 
  SET 
    full_name = COALESCE(public.profiles.full_name, au.raw_user_meta_data->>'full_name', 'User ' || LEFT(au.email::text, 10)),
    email = COALESCE(public.profiles.email, au.email),
    phone = COALESCE(public.profiles.phone, '+977-0000000000')
  FROM auth.users au
  WHERE au.id = public.profiles.user_id;
  
  RAISE NOTICE 'Updated profiles with user data';
END $$;

-- 9. Create missing profiles for booking users
DO $$
DECLARE
  user_record RECORD;
BEGIN
  FOR user_record IN 
    SELECT DISTINCT b.user_id, b.guest_phone
    FROM public.bookings b
    LEFT JOIN public.profiles p ON b.user_id = p.user_id
    WHERE p.user_id IS NULL
  LOOP
    INSERT INTO public.profiles (
      user_id,
      full_name,
      email,
      phone,
      created_at
    ) 
    SELECT 
      au.id,
      COALESCE(au.raw_user_meta_data->>'full_name', 'User ' || LEFT(au.email::text, 10)),
      au.email,
      COALESCE(user_record.guest_phone, '+977-0000000000'),
      NOW()
    FROM auth.users au
    WHERE au.id = user_record.user_id
    ON CONFLICT (user_id) DO NOTHING;
    
    RAISE NOTICE 'Created profile for user: %', user_record.user_id;
  END LOOP;
END $$;

-- 10. Final test of the exact frontend query
SELECT 
  'Final test of frontend query' as info,
  b.*,
  h.name,
  h.location,
  h.image_url,
  p.full_name,
  p.email
FROM public.bookings b
LEFT JOIN public.hotels h ON b.hotel_id = h.id
LEFT JOIN public.profiles p ON b.user_id = p.user_id
ORDER BY b.created_at DESC
LIMIT 5;

-- 11. Status check
SELECT 
  'Final status' as info,
  (SELECT COUNT(*) FROM public.bookings) as total_bookings,
  (SELECT COUNT(*) FROM public.profiles) as total_profiles,
  (SELECT COUNT(*) FROM public.bookings b LEFT JOIN public.profiles p ON b.user_id = p.user_id WHERE p.user_id IS NOT NULL) as bookings_with_profiles,
  'Frontend query should work now' as status;
