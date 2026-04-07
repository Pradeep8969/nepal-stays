# Database Setup Instructions for Nepal Stays

## Required Actions

Since your database is empty, you need to run the following SQL scripts in your Supabase dashboard:

### 1. Main Migration Script
Go to your Supabase dashboard:
1. Navigate to **SQL Editor**
2. Click **New query**
3. Copy and paste the contents of `supabase/migrations/20260407075602_5058260d-2c48-43e6-a761-e13f5d41b57e.sql`
4. Click **Run** to execute the migration

This will create:
- `user_roles` table for admin management
- `profiles` table for user information
- `hotels` table for hotel listings
- `bookings` table for reservations
- Row Level Security policies
- Trigger functions for automatic profile creation

### 2. Sample Data Script
After the migration completes successfully:
1. Create a new query in the SQL Editor
2. Copy and paste the contents of `sample-data.sql`
3. Click **Run** to insert sample hotels

This will add 10 sample hotels across Nepal including:
- Kathmandu, Pokhara, Chitwan, Bhaktapur, Nagarkot
- Lumbini, Namche Bazaar, Bandipur, Janakpur

## Environment Configuration
Your `.env` file is correctly configured with:
- Supabase URL: https://mxupfizfysfafgrtqgum.supabase.co
- Project ID: mxupfizfysfafgrtqgum
- Publishable key is set

## Next Steps
After running these scripts:
1. Test the application locally with `npm run dev` or `bun run dev`
2. Create an admin user by manually inserting into the `user_roles` table
3. Deploy to Vercel (already done)

## Admin User Creation
To create an admin user after signup:
```sql
INSERT INTO public.user_roles (user_id, role) 
VALUES ('USER_UUID_HERE', 'admin');
```

Replace `USER_UUID_HERE` with the actual user ID from the `auth.users` table.
