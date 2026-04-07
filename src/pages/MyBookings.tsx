import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/hooks/useAuth';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { useToast } from '@/hooks/use-toast';
import { differenceInDays, format } from 'date-fns';
import { CalendarDays, Users } from 'lucide-react';

interface BookingWithHotel {
  id: string;
  check_in_date: string;
  check_out_date: string;
  guests: number;
  room_type: string;
  total_price: number;
  status: string;
  created_at: string;
  hotels: { name: string; location: string; image_url: string } | null;
}

export default function MyBookings() {
  const { user } = useAuth();
  const { toast } = useToast();
  const [bookings, setBookings] = useState<BookingWithHotel[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchBookings = async () => {
    if (!user) return;
    const { data } = await supabase
      .from('bookings')
      .select('id, check_in_date, check_out_date, guests, room_type, total_price, status, created_at, hotels(name, location, image_url)')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });
    setBookings((data as unknown as BookingWithHotel[]) || []);
    setLoading(false);
  };

  useEffect(() => { fetchBookings(); }, [user]);

  const canCancel = (checkIn: string) => differenceInDays(new Date(checkIn), new Date()) >= 2;

  const handleCancel = async (id: string) => {
    const { error } = await supabase.from('bookings').update({ status: 'cancelled' }).eq('id', id);
    if (error) {
      toast({ title: 'Error', description: error.message, variant: 'destructive' });
    } else {
      toast({ title: 'Booking cancelled' });
      fetchBookings();
    }
  };

  if (loading) return <div className="container mx-auto px-4 py-12"><div className="h-40 animate-pulse rounded-lg bg-muted" /></div>;

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="mb-6 text-2xl font-bold text-foreground">My Bookings</h1>
      {bookings.length === 0 ? (
        <p className="py-12 text-center text-muted-foreground">You haven't made any bookings yet.</p>
      ) : (
        <div className="space-y-4">
          {bookings.map(b => (
            <Card key={b.id}>
              <CardContent className="flex flex-col gap-4 p-4 sm:flex-row sm:items-center">
                {b.hotels && (
                  <img src={b.hotels.image_url} alt={b.hotels.name} className="h-24 w-32 rounded-md object-cover" />
                )}
                <div className="flex-1 space-y-1">
                  <div className="flex items-center gap-2">
                    <h3 className="font-semibold text-foreground">{b.hotels?.name}</h3>
                    <Badge variant={b.status === 'confirmed' ? 'default' : 'secondary'}>
                      {b.status}
                    </Badge>
                  </div>
                  <p className="text-sm text-muted-foreground">{b.hotels?.location} · {b.room_type}</p>
                  <div className="flex flex-wrap gap-4 text-sm text-muted-foreground">
                    <span className="flex items-center gap-1"><CalendarDays className="h-3.5 w-3.5" />{format(new Date(b.check_in_date), 'MMM d')} → {format(new Date(b.check_out_date), 'MMM d, yyyy')}</span>
                    <span className="flex items-center gap-1"><Users className="h-3.5 w-3.5" />{b.guests} guest(s)</span>
                  </div>
                </div>
                <div className="flex items-center gap-4">
                  <span className="text-lg font-bold text-foreground">${b.total_price}</span>
                  {b.status === 'confirmed' && canCancel(b.check_in_date) && (
                    <Button variant="outline" size="sm" onClick={() => handleCancel(b.id)}>Cancel</Button>
                  )}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
