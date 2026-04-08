-- Test and Update Database - Step by Step
-- Run these commands one by one in Supabase SQL Editor

-- STEP 1: Test database connection and check current data
SELECT COUNT(*) as current_hotel_count FROM public.hotels;
SELECT name, LEFT(description, 50) as description_preview FROM public.hotels LIMIT 3;

-- STEP 2: Clear existing hotels (run this separately if needed)
-- DELETE FROM public.hotels;

-- STEP 3: Test with just one hotel first
INSERT INTO public.hotels (name, location, description, price_per_night, rating, image_url, rooms_available, room_types) VALUES
('Hotel Himalaya View', 'Kathmandu', 'Established in 1992, Hotel Himalaya View is renowned for its breathtaking panoramic views of the Himalayan range including Mount Everest on clear days. This family-run hotel is famous for its rooftop terrace where guests can enjoy sunrise views over the mountains while sipping traditional Nepali tea.', 120.00, 4.5, 'https://imgs.search.brave.com/JWoMOyjtJKLvmnoETTE-msDIgtFvCriUQK0jWoekrgU/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly92aXZl/bWVkaWEtMWQxNjgu/a3hjZG4uY29tLzM1/NTc5My8wLmpwZw', 15, '["Standard", "Deluxe", "Suite"]'::jsonb);

-- STEP 4: Verify the test hotel was added
SELECT COUNT(*) as total_hotels, name, LEFT(description, 100) as description_preview FROM public.hotels;

-- If this works, then run the complete enhanced SQL file
-- If not, check for errors in the Supabase SQL Editor console
