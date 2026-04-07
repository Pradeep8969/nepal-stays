import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Upload, X, Image as ImageIcon, Loader2 } from 'lucide-react';
import { PhotoStorage, UploadResult } from '@/integrations/supabase/storage';

interface PhotoUploadProps {
  onPhotosChange: (photos: string[]) => void;
  existingPhotos?: string[];
  hotelId?: string;
  maxPhotos?: number;
}

export default function PhotoUpload({ 
  onPhotosChange, 
  existingPhotos = [], 
  hotelId,
  maxPhotos = 5 
}: PhotoUploadProps) {
  const [photos, setPhotos] = useState<string[]>(existingPhotos);
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState<{ [key: string]: number }>({});

  const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const files = event.target.files;
    if (!files || !hotelId) return;

    setUploading(true);
    const newPhotos: string[] = [];

    try {
      // Ensure bucket exists
      await PhotoStorage.createBucketIfNotExists();

      // Upload files
      for (let i = 0; i < files.length && photos.length + newPhotos.length < maxPhotos; i++) {
        const file = files[i];
        const photoIndex = photos.length + newPhotos.length;
        
        const result = await PhotoStorage.uploadHotelPhoto(file, hotelId, photoIndex);
        
        if (result.error) {
          console.error(`Failed to upload ${file.name}:`, result.error);
          // You could show a toast notification here
          continue;
        }

        if (result.url) {
          newPhotos.push(result.url);
        }
      }

      const updatedPhotos = [...photos, ...newPhotos];
      setPhotos(updatedPhotos);
      onPhotosChange(updatedPhotos);

    } catch (error) {
      console.error('Upload failed:', error);
    } finally {
      setUploading(false);
      // Clear the input
      event.target.value = '';
    }
  };

  const removePhoto = (index: number) => {
    const updatedPhotos = photos.filter((_, i) => i !== index);
    setPhotos(updatedPhotos);
    onPhotosChange(updatedPhotos);
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <ImageIcon className="h-5 w-5" />
          Hotel Photos ({photos.length}/{maxPhotos})
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Photo Grid */}
        {photos.length > 0 && (
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
            {photos.map((photo, index) => (
              <div key={index} className="relative group">
                <img
                  src={photo}
                  alt={`Hotel photo ${index + 1}`}
                  className="w-full h-32 object-cover rounded-lg"
                />
                <Button
                  type="button"
                  variant="destructive"
                  size="sm"
                  className="absolute top-2 right-2 opacity-0 group-hover:opacity-100 transition-opacity"
                  onClick={() => removePhoto(index)}
                >
                  <X className="h-4 w-4" />
                </Button>
              </div>
            ))}
          </div>
        )}

        {/* Upload Button */}
        {photos.length < maxPhotos && (
          <div className="space-y-2">
            <Label htmlFor="photo-upload">Upload Photos</Label>
            <div className="flex items-center gap-2">
              <Input
                id="photo-upload"
                type="file"
                multiple
                accept="image/*"
                onChange={handleFileUpload}
                disabled={uploading || !hotelId}
                className="hidden"
              />
              <Button
                type="button"
                variant="outline"
                onClick={() => document.getElementById('photo-upload')?.click()}
                disabled={uploading || !hotelId}
                className="flex items-center gap-2"
              >
                {uploading ? (
                  <>
                    <Loader2 className="h-4 w-4 animate-spin" />
                    Uploading...
                  </>
                ) : (
                  <>
                    <Upload className="h-4 w-4" />
                    Choose Photos
                  </>
                )}
              </Button>
              <span className="text-sm text-muted-foreground">
                JPG, PNG up to 5MB each
              </span>
            </div>
            {!hotelId && (
              <p className="text-sm text-amber-600">
                Please save the hotel first before uploading photos.
              </p>
            )}
          </div>
        )}

        {/* Instructions */}
        <div className="text-sm text-muted-foreground">
          <p>Upload high-quality photos of your hotel. The first photo will be the main display image.</p>
          <p>Recommended: Exterior, lobby, rooms, amenities, and views.</p>
        </div>
      </CardContent>
    </Card>
  );
}
