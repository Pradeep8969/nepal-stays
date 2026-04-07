import { supabase } from './client';

export interface UploadResult {
  url: string;
  path: string;
  error?: string;
}

export class PhotoStorage {
  private static readonly BUCKET_NAME = 'hotel-photos';
  private static readonly MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB
  private static readonly ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp'];

  static async uploadHotelPhoto(
    file: File,
    hotelId: string,
    photoIndex: number
  ): Promise<UploadResult> {
    // Validate file
    if (!this.ALLOWED_TYPES.includes(file.type)) {
      return {
        url: '',
        path: '',
        error: 'Invalid file type. Only JPG, PNG, and WebP are allowed.'
      };
    }

    if (file.size > this.MAX_FILE_SIZE) {
      return {
        url: '',
        path: '',
        error: 'File size exceeds 5MB limit.'
      };
    }

    try {
      // Generate unique file name
      const fileExt = file.name.split('.').pop();
      const fileName = `${hotelId}/photo-${photoIndex + 1}-${Date.now()}.${fileExt}`;

      // Upload to Supabase Storage
      const { data, error } = await supabase.storage
        .from(this.BUCKET_NAME)
        .upload(fileName, file, {
          cacheControl: '3600',
          upsert: true
        });

      if (error) {
        return {
          url: '',
          path: '',
          error: error.message
        };
      }

      // Get public URL
      const { data: { publicUrl } } = supabase.storage
        .from(this.BUCKET_NAME)
        .getPublicUrl(data.path);

      return {
        url: publicUrl,
        path: data.path
      };

    } catch (error) {
      return {
        url: '',
        path: '',
        error: error instanceof Error ? error.message : 'Upload failed'
      };
    }
  }

  static async deleteHotelPhoto(path: string): Promise<{ error?: string }> {
    try {
      const { error } = await supabase.storage
        .from(this.BUCKET_NAME)
        .remove([path]);

      return { error: error?.message };
    } catch (error) {
      return { error: error instanceof Error ? error.message : 'Delete failed' };
    }
  }

  static async uploadMultipleHotelPhotos(
    files: File[],
    hotelId: string
  ): Promise<UploadResult[]> {
    const uploadPromises = files.map((file, index) => 
      this.uploadHotelPhoto(file, hotelId, index)
    );

    return Promise.all(uploadPromises);
  }

  static createBucketIfNotExists = async (): Promise<{ error?: string }> => {
    try {
      // Check if bucket exists
      const { data: buckets } = await supabase.storage.listBuckets();
      const bucketExists = buckets?.some(bucket => bucket.name === this.BUCKET_NAME);

      if (!bucketExists) {
        // Create bucket
        const { error } = await supabase.storage.createBucket(this.BUCKET_NAME, {
          public: true,
          allowedMimeTypes: this.ALLOWED_TYPES,
          fileSizeLimit: this.MAX_FILE_SIZE
        });

        return { error: error?.message };
      }

      return {};
    } catch (error) {
      return { error: error instanceof Error ? error.message : 'Bucket setup failed' };
    }
  };
}
