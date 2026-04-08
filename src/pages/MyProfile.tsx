import { useState, useEffect, useRef } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/hooks/useAuth';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Separator } from '@/components/ui/separator';
import { useToast } from '@/hooks/use-toast';
import { differenceInDays, format } from 'date-fns';
import { 
  User, 
  Mail, 
  Phone, 
  Calendar, 
  MapPin, 
  CreditCard, 
  Hotel, 
  Clock,
  FileText,
  Settings,
  LogOut,
  CheckCircle,
  XCircle,
  AlertCircle,
  Camera
} from 'lucide-react';

interface UserProfile {
  full_name: string;
  email: string;
  phone?: string;
  created_at: string;
  id: string;
  profile_photo?: string;
}

interface BookingWithHotel {
  id: string;
  check_in_date: string;
  check_out_date: string;
  guests: number;
  room_type: string;
  total_price: number;
  status: string;
  created_at: string;
  guest_phone: string;
  hotels: { name: string; location: string; image_url: string } | null;
}

export default function MyProfile() {
  const { user } = useAuth();
  const { toast } = useToast();
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [showInvoice, setShowInvoice] = useState(false);
  const [isUploadingPhoto, setIsUploadingPhoto] = useState(false);
  const [photoPreview, setPhotoPreview] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [recentBookings, setRecentBookings] = useState<BookingWithHotel[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchUserProfile = async () => {
    if (!user) return;
    
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('user_id', user.id)
      .single();
    
    if (error) {
      console.error('Error fetching profile:', error);
      // Fallback to user metadata if profile doesn't exist
      setUserProfile({
        id: user.id,
        full_name: user.user_metadata?.full_name || 'User',
        email: user.email || '',
        phone: user.user_metadata?.phone || '',
        created_at: user.created_at
      });
    } else {
      setUserProfile(data as UserProfile);
    }
  };

  const handleProfilePhotoUpdate = async (photoUrl: string) => {
    if (!user) return;
    
    try {
      const { error } = await supabase
        .from('profiles')
        .upsert({
          user_id: user.id,
          full_name: userProfile?.full_name || user.user_metadata?.full_name || 'User',
          email: userProfile?.email || user.email || '',
          phone: userProfile?.phone || user.user_metadata?.phone || '',
          profile_photo: photoUrl,
          created_at: userProfile?.created_at || user.created_at
        });

      if (error) {
        console.error('Error updating profile photo:', error);
        toast({
          title: 'Error',
          description: 'Failed to update profile photo.',
          variant: 'destructive',
        });
      } else {
        // Update local state
        setUserProfile(prev => prev ? { ...prev, profile_photo: photoUrl } : null);
        setPhotoPreview(null);
      }
    } catch (error) {
      console.error('Error updating profile photo:', error);
      toast({
        title: 'Error',
        description: 'Failed to update profile photo.',
        variant: 'destructive',
      });
    }
  };

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    // Validate file type
    if (!file.type.startsWith('image/')) {
      toast({
        title: 'Error',
        description: 'Please select an image file.',
        variant: 'destructive',
      });
      return;
    }

    // Validate file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
      toast({
        title: 'Error',
        description: 'Image size should be less than 5MB.',
        variant: 'destructive',
      });
      return;
    }

    // Create preview
    const reader = new FileReader();
    reader.onload = (e) => {
      const result = e.target?.result as string;
      setPhotoPreview(result);
    };
    reader.readAsDataURL(file);
  };

  const handleUploadPhoto = async () => {
    if (!photoPreview || !fileInputRef.current?.files?.[0]) return;

    setIsUploadingPhoto(true);
    
    try {
      const file = fileInputRef.current.files[0];
      
      // Convert to base64 and store
      const reader = new FileReader();
      reader.onload = async (e) => {
        const base64String = e.target?.result as string;
        
        // Store the base64 image
        await handleProfilePhotoUpdate(base64String);
        
        toast({
          title: 'Success',
          description: 'Profile photo updated successfully.',
        });
        setIsUploadingPhoto(false);
      };
      reader.readAsDataURL(file);
    } catch (error) {
      console.error('Error uploading photo:', error);
      toast({
        title: 'Error',
        description: 'Failed to upload photo. Please try again.',
        variant: 'destructive',
      });
      setIsUploadingPhoto(false);
    }
  };

  const handleRemovePhoto = async () => {
    setPhotoPreview(null);
    await handleProfilePhotoUpdate('');
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
    toast({
      title: 'Success',
      description: 'Profile photo removed.',
    });
  };

  const fetchRecentBookings = async () => {
    if (!user) return;
    
    const { data } = await supabase
      .from('bookings')
      .select('id, check_in_date, check_out_date, guests, room_type, total_price, status, created_at, guest_phone, hotels(name, location, image_url)')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });
    
    setRecentBookings((data as unknown as BookingWithHotel[]) || []);
  };

  useEffect(() => {
    const loadData = async () => {
      setLoading(true);
      await Promise.all([fetchUserProfile(), fetchRecentBookings()]);
      setLoading(false);
    };
    
    loadData();
  }, [user]);

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'confirmed':
        return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'cancelled':
        return <XCircle className="h-4 w-4 text-red-500" />;
      default:
        return <AlertCircle className="h-4 w-4 text-yellow-500" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'confirmed':
        return 'bg-green-100 text-green-800';
      case 'cancelled':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-yellow-100 text-yellow-800';
    }
  };

  if (loading) {
    return (
      <div className="container mx-auto px-4 py-12">
        <div className="max-w-4xl mx-auto space-y-6">
          <div className="h-40 animate-pulse rounded-lg bg-muted" />
          <div className="h-60 animate-pulse rounded-lg bg-muted" />
        </div>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-4xl mx-auto space-y-6">
        {/* Profile Header */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <User className="h-5 w-5" />
              My Profile
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex flex-col md:flex-row gap-6">
              <div className="flex flex-col items-center md:items-start">
                <div className="relative group">
                  <Avatar className="h-24 w-24 mb-4">
                    <AvatarImage src={photoPreview || userProfile?.profile_photo || user?.user_metadata?.avatar_url} />
                    <AvatarFallback className="text-2xl">
                      {userProfile?.full_name?.charAt(0) || 'U'}
                    </AvatarFallback>
                  </Avatar>
                  
                  <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                    <div className="bg-black bg-opacity-50 rounded-full h-24 w-24 flex items-center justify-center">
                      <Camera className="h-8 w-8 text-white" />
                    </div>
                  </div>
                </div>
                
                <div className="text-center md:text-left">
                  <h2 className="text-2xl font-bold">{userProfile?.full_name || 'User'}</h2>
                  <p className="text-muted-foreground">Member since {userProfile?.created_at ? format(new Date(userProfile.created_at), 'MMMM yyyy') : 'Unknown'}</p>
                </div>
                
                {/* Photo Upload Controls */}
                <div className="mt-4 space-y-2 w-full max-w-xs">
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*"
                    onChange={handleFileSelect}
                    className="hidden"
                    id="profile-photo-upload-header"
                  />
                  
                  <label htmlFor="profile-photo-upload-header">
                    <Button variant="outline" className="w-full cursor-pointer" asChild>
                      <span className="flex items-center gap-2">
                        <Camera className="h-4 w-4" />
                        Change Photo
                      </span>
                    </Button>
                  </label>

                  {(photoPreview || userProfile?.profile_photo) && (
                    <div className="flex gap-2">
                      {photoPreview && (
                        <Button 
                          onClick={handleUploadPhoto} 
                          disabled={isUploadingPhoto}
                          className="flex-1"
                        >
                          {isUploadingPhoto ? 'Saving...' : 'Save Photo'}
                        </Button>
                      )}
                      <Button 
                        variant="outline" 
                        onClick={handleRemovePhoto}
                        className="flex-1"
                      >
                        Remove Photo
                      </Button>
                    </div>
                  )}
                </div>
              </div>
              
              <div className="flex-1 grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="flex items-center gap-3">
                  <Mail className="h-5 w-5 text-muted-foreground" />
                  <div>
                    <p className="text-sm text-muted-foreground">Email</p>
                    <p className="font-medium">{userProfile?.email || user?.email}</p>
                  </div>
                </div>
                
                <div className="flex items-center gap-3">
                  <Phone className="h-5 w-5 text-muted-foreground" />
                  <div>
                    <p className="text-sm text-muted-foreground">Phone</p>
                    <p className="font-medium">{userProfile?.phone || 'Not provided'}</p>
                  </div>
                </div>
                
                <div className="flex items-center gap-3">
                  <User className="h-5 w-5 text-muted-foreground" />
                  <div>
                    <p className="text-sm text-muted-foreground">User ID</p>
                    <p className="font-mono text-sm">{userProfile?.id || user?.id}</p>
                  </div>
                </div>
                
                <div className="flex items-center gap-3">
                  <Calendar className="h-5 w-5 text-muted-foreground" />
                  <div>
                    <p className="text-sm text-muted-foreground">Account Created</p>
                    <p className="font-medium">{userProfile?.created_at ? format(new Date(userProfile.created_at), 'MMM d, yyyy') : 'Unknown'}</p>
                  </div>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* My Bookings */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Hotel className="h-5 w-5" />
              My Bookings
            </CardTitle>
          </CardHeader>
          <CardContent>
            {recentBookings.length === 0 ? (
              <div className="text-center py-8">
                <Hotel className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
                <p className="text-muted-foreground">No bookings yet</p>
                <Button className="mt-4" onClick={() => window.location.href = '/'}>
                  Browse Hotels
                </Button>
              </div>
            ) : (
              <div className="space-y-4">
                {recentBookings.map((booking) => (
                  <div key={booking.id} className="flex flex-col md:flex-row gap-4 p-4 border rounded-lg">
                    {booking.hotels && (
                      <img 
                        src={booking.hotels.image_url} 
                        alt={booking.hotels.name} 
                        className="h-20 w-24 rounded-md object-cover" 
                      />
                    )}
                    <div className="flex-1 space-y-2">
                      <div className="flex items-center justify-between">
                        <h3 className="font-semibold">{booking.hotels?.name}</h3>
                        <div className="flex items-center gap-2">
                          {getStatusIcon(booking.status)}
                          <Badge className={getStatusColor(booking.status)}>
                            {booking.status || 'pending'}
                          </Badge>
                        </div>
                      </div>
                      <p className="text-sm text-muted-foreground">{booking.hotels?.location} · {booking.room_type}</p>
                      <div className="flex flex-wrap gap-4 text-sm text-muted-foreground">
                        <span className="flex items-center gap-1">
                          <Calendar className="h-3.5 w-3.5" />
                          {format(new Date(booking.check_in_date), 'MMM d')} - {format(new Date(booking.check_out_date), 'MMM d, yyyy')}
                        </span>
                        <span className="flex items-center gap-1">
                          <User className="h-3.5 w-3.5" />
                          {booking.guests} guest(s)
                        </span>
                        {booking.guest_phone && (
                          <span className="flex items-center gap-1">
                            <Phone className="h-3.5 w-3.5" />
                            {booking.guest_phone}
                          </span>
                        )}
                      </div>
                      <div className="flex items-center justify-between">
                        <span className="text-lg font-bold">${booking.total_price}</span>
                        <span className="text-xs text-muted-foreground">
                          Booked {format(new Date(booking.created_at), 'MMM d, yyyy')}
                        </span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        {/* Quick Actions */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Settings className="h-5 w-5" />
              Quick Actions
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Button variant="outline" className="h-auto p-4 flex flex-col gap-2" onClick={() => window.location.href = '/my-bookings'}>
                <FileText className="h-6 w-6" />
                <span>My Bookings</span>
              </Button>
              <Button variant="outline" className="h-auto p-4 flex flex-col gap-2" onClick={() => window.location.href = '/'}>
                <Hotel className="h-6 w-6" />
                <span>Browse Hotels</span>
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
