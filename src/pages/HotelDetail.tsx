import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/hooks/useAuth';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { useToast } from '@/hooks/use-toast';
import { MapPin, Star, Users, Calendar, Phone } from 'lucide-react';
import type { Tables } from '@/integrations/supabase/types';
import { differenceInDays, format, addDays } from 'date-fns';
import { RoomTypeTooltip } from '@/components/RoomTypeTooltip';

export default function HotelDetail() {
  const { id } = useParams<{ id: string }>();
  const { user } = useAuth();
  const navigate = useNavigate();
  const { toast } = useToast();

  const [hotel, setHotel] = useState<Tables<'hotels'> | null>(null);
  const [loading, setLoading] = useState(true);
  const [checkIn, setCheckIn] = useState('');
  const [checkOut, setCheckOut] = useState('');
  const [guests, setGuests] = useState(1);
  const [roomType, setRoomType] = useState('');
  const [guestPhone, setGuestPhone] = useState('');
  const [booking, setBooking] = useState(false);

  useEffect(() => {
    const fetch = async () => {
      if (!id) return;
      const { data } = await supabase.from('hotels').select('*').eq('id', id).single();
      if (data) {
        setHotel(data);
        const types = data.room_types as string[];
        if (types.length > 0) setRoomType(types[0]);
      }
      setLoading(false);
    };
    fetch();
  }, [id]);

  const nights = checkIn && checkOut ? differenceInDays(new Date(checkOut), new Date(checkIn)) : 0;
  const totalPrice = hotel ? nights * hotel.price_per_night : 0;
  const today = format(new Date(), 'yyyy-MM-dd');
  const minCheckOut = checkIn ? format(addDays(new Date(checkIn), 1), 'yyyy-MM-dd') : today;

  const handleBook = async () => {
    if (!user) { navigate('/auth'); return; }
    if (nights <= 0) { toast({ title: 'Invalid dates', description: 'Check-out must be after check-in.', variant: 'destructive' }); return; }
    if (!guestPhone || guestPhone.length < 10) { 
      toast({ title: 'Invalid phone', description: 'Please enter a valid phone number for contact.', variant: 'destructive' }); 
      return; 
    }
    if (!hotel) return;

    setBooking(true);

    // Check availability
    const { count } = await supabase
      .from('bookings')
      .select('*', { count: 'exact', head: true })
      .eq('hotel_id', hotel.id)
      .eq('room_type', roomType)
      .eq('status', 'confirmed')
      .lt('check_in_date', checkOut)
      .gt('check_out_date', checkIn);

    if ((count ?? 0) >= hotel.rooms_available) {
      toast({ title: 'Not available', description: 'No rooms available for the selected dates.', variant: 'destructive' });
      setBooking(false);
      return;
    }

    const { error } = await supabase.from('bookings').insert({
      user_id: user.id,
      hotel_id: hotel.id,
      check_in_date: checkIn,
      check_out_date: checkOut,
      guests,
      room_type: roomType,
      total_price: totalPrice,
      guest_phone: guestPhone,
    });

    if (error) {
      toast({ title: 'Booking failed', description: error.message, variant: 'destructive' });
    } else {
      toast({ title: 'Booking confirmed!', description: `${hotel.name} - ${nights} night(s) for $${totalPrice}` });
      navigate('/my-bookings');
    }
    setBooking(false);
  };

  if (loading) return <div className="container mx-auto px-4 py-12"><div className="h-96 animate-pulse rounded-lg bg-muted" /></div>;
  if (!hotel) return <div className="container mx-auto px-4 py-12 text-center text-muted-foreground">Hotel not found.</div>;

  const roomTypes = hotel.room_types as string[];

  // Room type descriptions
  const getRoomTypeDescription = (roomType: string) => {
    const descriptions: { [key: string]: string } = {
      'Standard Room': 'Comfortable room with essential amenities including bed, private bathroom, TV, and free WiFi.',
      'Deluxe Room': 'Spacious room with premium amenities, comfortable seating area, and enhanced comfort features.',
      'Suite': 'Luxurious separate living area, bedroom, and premium amenities for ultimate comfort.',
      'Executive Room': 'Business-focused room with work desk, ergonomic chair, and business amenities.',
      'Family Room': 'Large room accommodating families with extra beds and child-friendly features.',
      'Ocean View': 'Room with stunning ocean views and balcony for scenic relaxation.',
      'Mountain View': 'Room offering breathtaking mountain views and natural surroundings.',
      'Garden View': 'Room overlooking beautiful gardens with peaceful atmosphere.',
      'Presidential Suite': 'Top-tier luxury suite with exclusive amenities and personalized service.',
      'Honeymoon Suite': 'Romantic suite with special amenities for couples celebrating.',
      'Twin Room': 'Room with two separate beds, perfect for friends or colleagues.',
      'Single Room': 'Compact room ideal for solo travelers with all essential amenities.',
      'Double Room': 'Room with one double bed, perfect for couples or single travelers.',
      'Triple Room': 'Room accommodating three guests with comfortable bedding arrangements.',
      'Quad Room': 'Spacious room designed for four guests with ample space.',
      'Penthouse': 'Top-floor luxury accommodation with panoramic views and premium features.',
      'Studio': 'Open-plan room combining living and sleeping areas efficiently.',
      'Apartment': 'Self-contained accommodation with kitchen facilities and separate living areas.',
      'Villa': 'Private luxury accommodation with garden, pool access, and exclusive amenities.',
      'Cottage': 'Cozy traditional accommodation with rustic charm and modern comforts.',
      'Bungalow': 'Single-story accommodation with spacious layout and private entrance.',
      'Loft': 'Stylish open-plan accommodation with high ceilings and modern design.',
      'Attic Room': 'Unique room in attic space with character and charm.',
      'Basement Room': 'Quiet underground room with cool temperature and privacy.',
      'Corner Room': 'Spacious room with windows on two sides providing extra light.',
      'Connecting Room': 'Rooms with connecting doors for families or groups.',
      'Adjoining Room': 'Adjacent rooms perfect for groups wanting proximity.',
      'Accessible Room': 'Specially designed room for guests with mobility needs.',
      'Pet-Friendly Room': 'Room where pets are welcome with special amenities.',
      'Non-Smoking Room': 'Clean fresh room strictly for non-smokers.',
      'Smoking Room': 'Designated smoking room with proper ventilation.',
      'Economy Room': 'Budget-friendly room with essential amenities at great value.',
      'Budget Room': 'Affordable accommodation without compromising on comfort.',
      'Luxury Room': 'Premium room with high-end amenities and superior comfort.',
      'Premium Room': 'Enhanced room with upgraded features and exclusive services.',
      'Classic Room': 'Timeless elegant room with traditional decor and comfort.',
      'Modern Room': 'Contemporary room with sleek design and modern amenities.',
      'Traditional Room': 'Room featuring local cultural elements and traditional decor.',
      'Heritage Room': 'Historic room with preserved architectural features.',
      'Vintage Room': 'Retro-styled room with vintage charm and character.',
      'Contemporary Room': 'Modern room with current design trends and technology.',
      'Minimalist Room': 'Clean, simple room with essential amenities and clutter-free space.',
      'Rustic Room': 'Room with natural materials and countryside charm.',
      'Urban Room': 'City-focused room with modern urban design elements.',
      'Beachfront Room': 'Direct beach access with ocean views and beach amenities.',
      'Lake View Room': 'Room overlooking serene lake with peaceful views.',
      'River View Room': 'Room with beautiful river views and tranquil atmosphere.',
      'City View Room': 'Room offering panoramic city skyline views.',
      'Park View Room': 'Room overlooking green park with natural scenery.',
      'Garden Room': 'Room with direct garden access and outdoor space.',
      'Terrace Room': 'Room with private terrace for outdoor relaxation.',
      'Balcony Room': 'Room with private balcony for fresh air and views.',
      'Rooftop Room': 'Top-floor room with rooftop access and panoramic views.',
      'Penthouse Suite': 'Luxurious top-floor suite with exclusive rooftop amenities.',
      'Royal Suite': 'Ultra-luxurious suite with royal treatment and premium services.',
      'Imperial Suite': 'Grand luxurious suite with imperial-level amenities.',
      'Grand Suite': 'Spacious luxurious suite with premium comfort and elegance.',
      'Master Suite': 'Large suite with separate living areas and master bedroom.',
      'Junior Suite': 'Compact suite with sitting area and enhanced amenities.',
      'Bridal Suite': 'Special romantic suite for newlyweds with honeymoon amenities.',
      'Anniversary Suite': 'Romantic suite perfect for celebrating special occasions.',
      'Business Suite': 'Suite designed for business travelers with work facilities.',
      'Conference Room': 'Meeting room with business facilities and equipment.',
      'Meeting Room': 'Professional space for business meetings and presentations.',
      'Executive Suite': 'Premium suite with business amenities and executive services.',
      'Corporate Room': 'Room designed for corporate travelers with work amenities.',
      'Diplomatic Suite': 'High-security suite for diplomatic guests and officials.',
      'VIP Suite': 'Very important person suite with exclusive services and security.',
      'Celebrity Suite': 'Private suite with enhanced privacy and celebrity amenities.',
      'Artist Suite': 'Creative suite with artistic decor and inspiration spaces.',
      'Writer Suite': 'Quiet suite designed for writers with peaceful work environment.',
      'Photographer Suite': 'Suite with natural lighting and photo opportunities.',
      'Musician Suite': 'Sound-proofed suite with music amenities and practice space.',
      'Designer Suite': 'Stylish suite with contemporary design and artistic elements.',
      'Architect Suite': 'Suite with architectural interest and design inspiration.',
      'Chef Suite': 'Suite with kitchen facilities for culinary enthusiasts.',
      'Wine Suite': 'Suite with wine cellar and tasting amenities.',
      'Spa Suite': 'Suite with private spa facilities and wellness amenities.',
      'Wellness Suite': 'Health-focused suite with fitness and wellness equipment.',
      'Yoga Suite': 'Suite with yoga space and meditation amenities.',
      'Fitness Suite': 'Suite with private gym and fitness equipment.',
      'Sports Suite': 'Suite with sports amenities and equipment storage.',
      'Golf Suite': 'Suite for golf enthusiasts with golf-related amenities.',
      'Tennis Suite': 'Suite for tennis players with court access and amenities.',
      'Ski Suite': 'Suite for skiers with equipment storage and ski amenities.',
      'Adventure Suite': 'Suite for adventure travelers with equipment storage.',
      'Eco Suite': 'Environmentally friendly suite with sustainable amenities.',
      'Green Room': 'Eco-conscious room with sustainable materials and practices.',
      'Solar Room': 'Energy-efficient room with solar-powered amenities.',
      'Smart Room': 'Technology-enabled room with smart home features.',
      'Tech Room': 'High-tech room with advanced technology and gadgets.',
      'Digital Room': 'Room with digital amenities and entertainment systems.',
      'Gaming Room': 'Room with gaming consoles and entertainment systems.',
      'Entertainment Room': 'Room with comprehensive entertainment systems.',
      'Media Room': 'Room with advanced media and entertainment equipment.',
      'Theater Room': 'Room with home theater system and entertainment.',
      'Cinema Room': 'Private cinema room with movie-watching amenities.',
      'Library Room': 'Room with library facilities and reading space.',
      'Study Room': 'Quiet room designed for studying and work.',
      'Reading Room': 'Comfortable room dedicated to reading and relaxation.',
      'Art Room': 'Room with artistic decor and creative inspiration.',
      'Gallery Room': 'Room displaying art and cultural pieces.',
      'Museum Room': 'Room with museum-quality decor and artifacts.',
      'Cultural Room': 'Room featuring local culture and traditional elements.',
      'Historic Room': 'Room with historical significance and preserved features.',
      'Antique Room': 'Room with antique furniture and vintage decor.',
      'Collector Room': 'Room designed for collectors with display spaces.',
      'Exhibition Room': 'Room suitable for exhibitions and displays.',
      'Showroom Room': 'Room designed for showcasing products and designs.',
      'Display Room': 'Room with display facilities for presentations.',
      'Presentation Room': 'Professional room for presentations and meetings.',
      'Training Room': 'Room designed for training and educational purposes.',
      'Classroom Room': 'Educational room with learning facilities.',
      'Seminar Room': 'Room suitable for seminars and workshops.',
      'Workshop Room': 'Room designed for hands-on workshops and activities.',
      'Studio Room': 'Creative space for artistic and design work.',
      'Art Studio': 'Room dedicated to artistic creation and expression.',
      'Design Studio': 'Professional room for design work and creativity.',
      'Creative Room': 'Room designed to inspire creativity and innovation.',
      'Innovation Room': 'Room for innovation and creative thinking.',
      'Brainstorm Room': 'Room designed for brainstorming and idea generation.',
      'Strategy Room': 'Professional room for strategic planning and meetings.',
      'Board Room': 'Executive board room with meeting facilities.',
      'Executive Room': 'Professional room for executive meetings and work.',
      'Management Room': 'Room designed for management and administrative work.',
      'Administrative Room': 'Room for administrative tasks and office work.',
      'Office Room': 'Professional room with office amenities and workspace.',
      'Work Room': 'Functional room designed for work and productivity.',
      'Productivity Room': 'Room optimized for maximum productivity and focus.',
      'Focus Room': 'Quiet room designed for concentration and deep work.',
      'Quiet Room': 'Silent room for relaxation and meditation.',
      'Meditation Room': 'Room designed for meditation and mindfulness.',
      'Relaxation Room': 'Room dedicated to relaxation and stress relief.',
      'Zen Room': 'Peaceful room with zen-inspired decor and atmosphere.',
      'Peace Room': 'Tranquil room designed for peace and serenity.',
      'Tranquility Room': 'Room with peaceful atmosphere and calming decor.',
      'Harmony Room': 'Room designed for balance and harmony.',
      'Balance Room': 'Room with balanced design and peaceful energy.',
      'Wellness Room': 'Room focused on health and wellness activities.',
      'Health Room': 'Room with health-focused amenities and facilities.',
      'Medical Room': 'Room with medical facilities and first aid.',
      'Clinic Room': 'Room designed for medical consultations and treatments.',
      'Therapy Room': 'Room for therapy sessions and healing activities.',
      'Recovery Room': 'Room designed for rest and recovery.',
      'Rest Room': 'Quiet room for rest and relaxation.',
      'Lounge Room': 'Comfortable room for lounging and relaxation.',
      'Social Room': 'Room designed for social gatherings and interactions.',
      'Community Room': 'Room for community activities and gatherings.',
      'Gathering Room': 'Spacious room for group gatherings and events.',
      'Event Room': 'Room suitable for hosting events and celebrations.',
      'Party Room': 'Room designed for parties and celebrations.',
      'Celebration Room': 'Room perfect for special occasions and celebrations.',
      'Festive Room': 'Room with festive decor and celebration atmosphere.',
      'Holiday Room': 'Room designed for holiday experiences and celebrations.',
      'Vacation Room': 'Room optimized for vacation relaxation and enjoyment.',
      'Holiday Suite': 'Luxury suite designed for holiday experiences.',
      'Vacation Suite': 'Spacious suite perfect for extended vacation stays.',
      'Getaway Room': 'Room designed for romantic getaways and escapes.',
      'Escape Room': 'Room designed for peaceful escapes and relaxation.',
      'Hideaway Room': 'Private room for secluded and intimate experiences.',
      'Secret Room': 'Exclusive room with privacy and discretion.',
      'Private Room': 'Room with maximum privacy and exclusivity.',
      'Exclusive Room': 'Room with exclusive amenities and VIP treatment.',
      'Elite Room': 'Premium room with elite-level amenities and services.',
      'Platinum Room': 'Top-tier room with platinum-level luxury and amenities.',
      'Gold Room': 'Luxury room with gold-level amenities and services.',
      'Silver Room': 'Premium room with silver-level amenities.',
      'Bronze Room': 'Comfortable room with bronze-level amenities.',
      'Diamond Room': 'Ultra-luxury room with diamond-level amenities.',
      'Ruby Room': 'Luxury room with ruby-themed decor and amenities.',
      'Emerald Room': 'Room with emerald-inspired decor and luxury amenities.',
      'Sapphire Room': 'Room with sapphire-themed decor and premium features.',
      'Pearl Room': 'Elegant room with pearl-inspired decor and amenities.',
      'Crystal Room': 'Room with crystal decor and luxury amenities.',
      'Jade Room': 'Room with jade-inspired decor and peaceful atmosphere.',
      'Opal Room': 'Room with opal-inspired decor and colorful amenities.',
      'Amber Room': 'Room with amber-themed decor and warm atmosphere.',
      'Ivory Room': 'Elegant room with ivory-themed decor and luxury.',
      'Marble Room': 'Room with marble decor and luxury amenities.',
      'Granite Room': 'Room with granite decor and premium features.',
      'Wood Room': 'Room with natural wood decor and warm atmosphere.',
      'Stone Room': 'Room with stone decor and natural elements.',
      'Glass Room': 'Modern room with glass walls and contemporary design.',
      'Mirror Room': 'Room with mirror decor and spacious feel.',
      'Chrome Room': 'Modern room with chrome accents and sleek design.',
      'Steel Room': 'Industrial room with steel elements and modern decor.',
      'Iron Room': 'Room with iron decor and industrial design.',
      'Copper Room': 'Room with copper accents and warm metallic decor.',
      'Brass Room': 'Room with brass decor and vintage elegance.',
      'Bronze Room': 'Room with bronze decor and classic elegance.',
      'Titanium Room': 'Modern room with titanium elements and sleek design.',
      'Platinum Room': 'Luxury room with platinum decor and premium amenities.',
      'Aluminum Room': 'Modern room with aluminum elements and contemporary design.',
      'Nickel Room': 'Room with nickel decor and metallic elegance.',
      'Zinc Room': 'Room with zinc elements and industrial charm.',
      'Lead Room': 'Room with lead elements and classic durability.',
      'Tin Room': 'Room with tin decor and vintage charm.',
      'Silver Room': 'Elegant room with silver decor and luxury amenities.',
      'Gold Room': 'Luxury room with gold accents and premium features.',
      'Platinum Room': 'Ultra-luxury room with platinum decor and elite amenities.'
    };
    
    return descriptions[roomType] || 'Comfortable room with essential amenities for a pleasant stay.';
  };

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="grid gap-8 lg:grid-cols-3">
        {/* Hotel info */}
        <div className="lg:col-span-2">
          <div className="mb-6 overflow-hidden rounded-lg">
            <img src={hotel.image_url} alt={hotel.name} className="h-72 w-full object-cover sm:h-96" />
          </div>
          <h1 className="mb-2 text-2xl font-bold text-foreground">{hotel.name}</h1>
          <div className="mb-4 flex flex-wrap items-center gap-4">
            <div className="flex items-center gap-1 text-muted-foreground"><MapPin className="h-4 w-4" />{hotel.location}</div>
            <div className="flex items-center gap-1 text-warning"><Star className="h-4 w-4 fill-current" />{hotel.rating}</div>
            <span className="text-lg font-bold text-primary">${hotel.price_per_night}/night</span>
          </div>
          <p className="mb-6 leading-relaxed text-muted-foreground">{hotel.description}</p>

          <h2 className="mb-3 text-lg font-semibold text-foreground">Room Types</h2>
          <div className="flex flex-wrap gap-2">
            {roomTypes.map(type => (
              <RoomTypeTooltip 
                key={type} 
                roomType={type} 
                description={getRoomTypeDescription(type)} 
              />
            ))}
          </div>
        </div>

        {/* Booking card */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2"><Calendar className="h-5 w-5 text-primary" /> Book This Hotel</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label>Check-in</Label>
              <Input type="date" min={today} value={checkIn} onChange={e => setCheckIn(e.target.value)} />
            </div>
            <div className="space-y-2">
              <Label>Check-out</Label>
              <Input type="date" min={minCheckOut} value={checkOut} onChange={e => setCheckOut(e.target.value)} />
            </div>
            <div className="space-y-2">
              <Label>Guests</Label>
              <div className="flex items-center gap-2">
                <Users className="h-4 w-4 text-muted-foreground" />
                <Input type="number" min={1} max={10} value={guests} onChange={e => setGuests(Number(e.target.value))} />
              </div>
            </div>
            <div className="space-y-2">
              <Label>Room Type</Label>
              <Select value={roomType} onValueChange={setRoomType}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  {roomTypes.map(type => <SelectItem key={type} value={type}>{type}</SelectItem>)}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label>Guest Phone Number</Label>
              <div className="flex items-center gap-2">
                <Phone className="h-4 w-4 text-muted-foreground" />
                <Input 
                  type="tel" 
                  placeholder="+977-XXXXXXXXX" 
                  value={guestPhone} 
                  onChange={e => setGuestPhone(e.target.value)}
                />
              </div>
              <p className="text-xs text-muted-foreground">Required for contact during your stay</p>
            </div>

            {nights > 0 && (
              <div className="rounded-lg bg-accent p-3">
                <div className="flex justify-between text-sm"><span>{nights} night(s) × ${hotel.price_per_night}</span><span className="font-semibold">${totalPrice}</span></div>
              </div>
            )}

            <Button className="w-full" onClick={handleBook} disabled={booking || !checkIn || !checkOut}>
              {booking ? 'Booking...' : user ? 'Confirm Booking' : 'Sign in to Book'}
            </Button>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
