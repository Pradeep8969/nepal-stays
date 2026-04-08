import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Slider } from '@/components/ui/slider';
import HotelCard from '@/components/HotelCard';
import { Search } from 'lucide-react';
import type { Tables } from '@/integrations/supabase/types';

const LOCATIONS = ['All', 'Kathmandu', 'Pokhara', 'Chitwan', 'Lumbini', 'Annapurna'];

export default function Index() {
  const [hotels, setHotels] = useState<Tables<'hotels'>[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [location, setLocation] = useState('All');
  const [priceRange, setPriceRange] = useState([0, 300]);

  useEffect(() => {
    const fetchHotels = async () => {
      const { data } = await supabase.from('hotels').select('*').order('rating', { ascending: false });
      setHotels(data || []);
      setLoading(false);
    };
    fetchHotels();
  }, []);

  const filtered = hotels.filter(h => {
    const matchesSearch = h.name.toLowerCase().includes(search.toLowerCase());
    const matchesLocation = location === 'All' || h.location === location;
    const matchesPrice = h.price_per_night >= priceRange[0] && h.price_per_night <= priceRange[1];
    return matchesSearch && matchesLocation && matchesPrice;
  });

  return (
    <div className="container mx-auto px-4 py-8">
      {/* Hero */}
      <div className="mb-8 text-center">
        <h1 className="mb-2 text-3xl font-bold text-foreground">Discover Nepal</h1>
        <p className="text-muted-foreground">Find the perfect stay across Nepal's most beautiful destinations</p>
      </div>

      {/* Filters */}
      <div className="mb-8 grid gap-4 rounded-lg border bg-card p-4 sm:grid-cols-3">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input placeholder="Search hotels..." value={search} onChange={e => setSearch(e.target.value)} className="pl-9" />
        </div>
        <Select value={location} onValueChange={setLocation}>
          <SelectTrigger><SelectValue placeholder="Location" /></SelectTrigger>
          <SelectContent>
            {LOCATIONS.map(loc => <SelectItem key={loc} value={loc}>{loc}</SelectItem>)}
          </SelectContent>
        </Select>
        <div className="space-y-1">
          <div className="flex justify-between text-xs text-muted-foreground">
            <span>Price: ${priceRange[0]}</span>
            <span>${priceRange[1]}+</span>
          </div>
          <Slider min={0} max={300} step={10} value={priceRange} onValueChange={setPriceRange} />
        </div>
      </div>

      {/* Results */}
      {loading ? (
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {[...Array(6)].map((_, i) => (
            <div key={i} className="h-80 animate-pulse rounded-lg bg-muted" />
          ))}
        </div>
      ) : filtered.length === 0 ? (
        <p className="py-12 text-center text-muted-foreground">No hotels found matching your criteria.</p>
      ) : (
        <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {filtered.map(hotel => <HotelCard key={hotel.id} hotel={hotel} />)}
        </div>
      )}
    </div>
  );
}
