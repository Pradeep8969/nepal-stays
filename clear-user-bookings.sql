-- Clear all bookings for pradeep.pandey8969@gmail.com
-- Run this in Supabase SQL Editor

-- First, let's see what bookings exist for this user
SELECT 
    b.id,
    b.check_in_date,
    b.check_out_date,
    b.guests,
    b.room_type,
    b.total_price,
    b.status,
    b.created_at,
    h.name as hotel_name,
    h.location
FROM bookings b
JOIN hotels h ON b.hotel_id = h.id
WHERE b.user_id = (
    SELECT id FROM auth.users 
    WHERE email = 'pradeep.pandey8969@gmail.com'
)
ORDER BY b.created_at DESC;

-- Now delete all bookings for this user
DELETE FROM bookings 
WHERE user_id = (
    SELECT id FROM auth.users 
    WHERE email = 'pradeep.pandey8969@gmail.com'
);

-- Verify the bookings were deleted
SELECT COUNT(*) as remaining_bookings 
FROM bookings 
WHERE user_id = (
    SELECT id FROM auth.users 
    WHERE email = 'pradeep.pandey8969@gmail.com'
);
