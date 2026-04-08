-- Add phone number field to bookings table
-- Run this in Supabase SQL Editor

-- Add phone number column to bookings table
ALTER TABLE public.bookings 
ADD COLUMN guest_phone VARCHAR(20);

-- Add comment for documentation
COMMENT ON COLUMN public.bookings.guest_phone IS 'Guest phone number for contact during stay';

-- Update existing bookings to have null phone numbers (optional)
UPDATE public.bookings 
SET guest_phone = NULL 
WHERE guest_phone IS NULL;

-- Verify the column was added
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'bookings' 
AND table_schema = 'public';
