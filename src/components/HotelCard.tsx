import { Link } from 'react-router-dom';
import { Card, CardContent } from '@/components/ui/card';
import { MapPin, Star } from 'lucide-react';
import type { Tables } from '@/integrations/supabase/types';

interface HotelCardProps {
  hotel: Tables<'hotels'>;
}

export default function HotelCard({ hotel }: HotelCardProps) {
  return (
    <Link to={`/hotel/${hotel.id}`}>
      <Card className="overflow-hidden transition-shadow hover:shadow-md">
        <div className="aspect-[16/10] overflow-hidden">
          <img
            src={hotel.image_url}
            alt={hotel.name}
            className="h-full w-full object-cover transition-transform hover:scale-105"
            loading="lazy"
          />
        </div>
        <CardContent className="p-4">
          <div className="mb-1 flex items-center justify-between">
            <h3 className="font-semibold text-foreground">{hotel.name}</h3>
            <div className="flex items-center gap-1 text-sm text-warning">
              <Star className="h-4 w-4 fill-current" />
              <span>{hotel.rating}</span>
            </div>
          </div>
          <div className="mb-2 flex items-center gap-1 text-sm text-muted-foreground">
            <MapPin className="h-3.5 w-3.5" />
            <span>{hotel.location}</span>
          </div>
          <p className="mb-3 line-clamp-2 text-sm text-muted-foreground">{hotel.description}</p>
          <div className="flex items-center justify-between">
            <span className="text-lg font-bold text-foreground">${hotel.price_per_night}<span className="text-sm font-normal text-muted-foreground">/night</span></span>
            <span className="text-xs text-muted-foreground">{hotel.rooms_available} rooms left</span>
          </div>
        </CardContent>
      </Card>
    </Link>
  );
}
