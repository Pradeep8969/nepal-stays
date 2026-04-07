import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/hooks/useAuth';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { useToast } from '@/hooks/use-toast';
import { Pencil, Trash2, Plus } from 'lucide-react';
import type { Tables } from '@/integrations/supabase/types';
import { Textarea } from '@/components/ui/textarea';

const emptyHotel = { name: '', location: '', description: '', price_per_night: 0, rating: 4.0, image_url: '', rooms_available: 10, room_types: '["Standard", "Deluxe"]' };

export default function Admin() {
  const { isAdmin } = useAuth();
  const { toast } = useToast();
  const [hotels, setHotels] = useState<Tables<'hotels'>[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editing, setEditing] = useState<string | null>(null);
  const [form, setForm] = useState(emptyHotel);

  const fetchHotels = async () => {
    const { data } = await supabase.from('hotels').select('*').order('created_at', { ascending: false });
    setHotels(data || []);
    setLoading(false);
  };

  useEffect(() => { fetchHotels(); }, []);

  if (!isAdmin) return <div className="container mx-auto px-4 py-12 text-center text-muted-foreground">Access denied. Admin only.</div>;

  const openNew = () => { setForm(emptyHotel); setEditing(null); setDialogOpen(true); };
  const openEdit = (h: Tables<'hotels'>) => {
    setForm({
      name: h.name, location: h.location, description: h.description,
      price_per_night: h.price_per_night, rating: h.rating,
      image_url: h.image_url, rooms_available: h.rooms_available,
      room_types: JSON.stringify(h.room_types),
    });
    setEditing(h.id);
    setDialogOpen(true);
  };

  const handleSave = async () => {
    let roomTypes: string[];
    try { roomTypes = JSON.parse(form.room_types); } catch { toast({ title: 'Invalid room types JSON', variant: 'destructive' }); return; }

    const payload = { ...form, price_per_night: Number(form.price_per_night), rating: Number(form.rating), rooms_available: Number(form.rooms_available), room_types: roomTypes };

    if (editing) {
      const { error } = await supabase.from('hotels').update(payload).eq('id', editing);
      if (error) { toast({ title: 'Error', description: error.message, variant: 'destructive' }); return; }
      toast({ title: 'Hotel updated' });
    } else {
      const { error } = await supabase.from('hotels').insert(payload);
      if (error) { toast({ title: 'Error', description: error.message, variant: 'destructive' }); return; }
      toast({ title: 'Hotel added' });
    }
    setDialogOpen(false);
    fetchHotels();
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Delete this hotel?')) return;
    const { error } = await supabase.from('hotels').delete().eq('id', id);
    if (error) { toast({ title: 'Error', description: error.message, variant: 'destructive' }); return; }
    toast({ title: 'Hotel deleted' });
    fetchHotels();
  };

  const updateField = (field: string, value: string | number) => setForm(prev => ({ ...prev, [field]: value }));

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold text-foreground">Admin Panel</h1>
        <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
          <DialogTrigger asChild>
            <Button onClick={openNew}><Plus className="mr-2 h-4 w-4" /> Add Hotel</Button>
          </DialogTrigger>
          <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-lg">
            <DialogHeader><DialogTitle>{editing ? 'Edit Hotel' : 'Add Hotel'}</DialogTitle></DialogHeader>
            <div className="space-y-3">
              <div><Label>Name</Label><Input value={form.name} onChange={e => updateField('name', e.target.value)} /></div>
              <div><Label>Location</Label><Input value={form.location} onChange={e => updateField('location', e.target.value)} /></div>
              <div><Label>Description</Label><Textarea value={form.description} onChange={e => updateField('description', e.target.value)} /></div>
              <div className="grid grid-cols-2 gap-3">
                <div><Label>Price/Night ($)</Label><Input type="number" value={form.price_per_night} onChange={e => updateField('price_per_night', e.target.value)} /></div>
                <div><Label>Rating</Label><Input type="number" step="0.1" min="1" max="5" value={form.rating} onChange={e => updateField('rating', e.target.value)} /></div>
              </div>
              <div><Label>Image URL</Label><Input value={form.image_url} onChange={e => updateField('image_url', e.target.value)} /></div>
              <div><Label>Rooms Available</Label><Input type="number" value={form.rooms_available} onChange={e => updateField('rooms_available', e.target.value)} /></div>
              <div><Label>Room Types (JSON array)</Label><Input value={form.room_types} onChange={e => updateField('room_types', e.target.value)} /></div>
              <Button className="w-full" onClick={handleSave}>{editing ? 'Update' : 'Add'} Hotel</Button>
            </div>
          </DialogContent>
        </Dialog>
      </div>

      {loading ? (
        <div className="h-40 animate-pulse rounded-lg bg-muted" />
      ) : (
        <div className="space-y-3">
          {hotels.map(h => (
            <Card key={h.id}>
              <CardContent className="flex items-center gap-4 p-4">
                <img src={h.image_url} alt={h.name} className="h-16 w-20 rounded-md object-cover" />
                <div className="flex-1">
                  <h3 className="font-semibold text-foreground">{h.name}</h3>
                  <p className="text-sm text-muted-foreground">{h.location} · ${h.price_per_night}/night · {h.rooms_available} rooms</p>
                </div>
                <div className="flex gap-2">
                  <Button variant="outline" size="icon" onClick={() => openEdit(h)}><Pencil className="h-4 w-4" /></Button>
                  <Button variant="outline" size="icon" onClick={() => handleDelete(h.id)}><Trash2 className="h-4 w-4" /></Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
