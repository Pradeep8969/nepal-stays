-- Migration to add hotel photos support
-- Run this after the main migration

-- Create hotel_photos table
CREATE TABLE public.hotel_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  hotel_id UUID REFERENCES public.hotels(id) ON DELETE CASCADE NOT NULL,
  photo_url TEXT NOT NULL,
  photo_path TEXT, -- For Supabase Storage path
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.hotel_photos ENABLE ROW LEVEL SECURITY;

-- Policies for hotel photos
CREATE POLICY "Hotel photos are viewable by everyone" ON public.hotel_photos FOR SELECT USING (true);
CREATE POLICY "Admins can insert hotel photos" ON public.hotel_photos FOR INSERT WITH CHECK (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins can update hotel photos" ON public.hotel_photos FOR UPDATE USING (public.has_role(auth.uid(), 'admin'));
CREATE POLICY "Admins can delete hotel photos" ON public.hotel_photos FOR DELETE USING (public.has_role(auth.uid(), 'admin'));

-- Function to ensure only one primary photo per hotel
CREATE OR REPLACE FUNCTION public.ensure_single_primary_photo()
RETURNS TRIGGER AS $$
BEGIN
  -- If this photo is being set as primary, unset other primary photos for this hotel
  IF NEW.is_primary = TRUE THEN
    UPDATE public.hotel_photos 
    SET is_primary = FALSE 
    WHERE hotel_id = NEW.hotel_id AND id != NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql

-- Trigger to enforce single primary photo
CREATE TRIGGER ensure_single_primary_photo_trigger
  BEFORE INSERT OR UPDATE ON public.hotel_photos
  FOR EACH ROW EXECUTE FUNCTION public.ensure_single_primary_photo();

-- Trigger for updated_at
CREATE TRIGGER update_hotel_photos_updated_at 
  BEFORE UPDATE ON public.hotel_photos 
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Function to get hotel photos with proper ordering
CREATE OR REPLACE FUNCTION public.get_hotel_photos(hotel_uuid UUID)
RETURNS TABLE (
  id UUID,
  photo_url TEXT,
  photo_path TEXT,
  is_primary BOOLEAN,
  display_order INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    hp.id,
    hp.photo_url,
    hp.photo_path,
    hp.is_primary,
    hp.display_order
  FROM public.hotel_photos hp
  WHERE hp.hotel_id = hotel_uuid
  ORDER BY 
    hp.is_primary DESC,
    hp.display_order ASC,
    hp.created_at ASC;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- Update hotels table to keep backward compatibility
-- The image_url column will still be used as fallback
COMMENT ON COLUMN public.hotels.image_url IS 'Fallback image URL. Use hotel_photos table for multiple images.';
