# Fix Schema Cache Issue

## Problem: TypeScript types don't include the new guest_phone column

## Solution Steps:

### 1. Run the Database Migration First
Execute this SQL in Supabase dashboard:
```sql
ALTER TABLE public.bookings 
ADD COLUMN guest_phone VARCHAR(20);
```

### 2. Regenerate TypeScript Types
Run this command to update the types:

```bash
npx supabase gen types typescript --project-id mxupfizfysfafgrtqgum --schema public > src/integrations/supabase/types.ts
```

### 3. Alternative: Manual Type Refresh
If the above doesn't work, try:
```bash
npx supabase db reset
```

### 4. Restart Development Server
```bash
npm run dev
```

## What I've Already Fixed:
- Updated TypeScript types manually to include guest_phone
- Added guest_phone field to booking form
- Updated MyBookings to display phone numbers
- Updated Invoice to include phone numbers

## Next Steps:
1. Make sure the SQL migration is run in Supabase
2. Restart your development server
3. Test the booking functionality

The error should be resolved once the database schema is updated!
