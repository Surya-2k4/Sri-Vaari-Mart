# Database Setup Guide - RLS Policies for Admin Panel

## Issue
The admin panel is getting a `PostgrestException: new row violates row-level security policy` error when trying to add/edit/delete products or orders. This is because Supabase has Row Level Security (RLS) enabled but no policies allow admin operations.

## Solution: Add RLS Policies in Supabase

### Step 1: Go to Supabase Dashboard
1. Open your Supabase project dashboard
2. Go to **Authentication** → **Policies**
3. Or go to **Database** → **Tables** → Select table → **RLS Policies**

### Step 2: Add Policies for Products Table

Run these SQL commands in the Supabase SQL Editor:

-- Enable RLS on products table (if not already enabled)
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Add image_urls column for multi-image support (Run this if adding products fails)
ALTER TABLE products ADD COLUMN IF NOT EXISTS image_urls jsonb DEFAULT '[]'::jsonb;

-- Policy: Allow all authenticated users to SELECT products
CREATE POLICY "Allow public to read products"
ON products FOR SELECT
TO authenticated, anon
USING (true);

-- Policy: Allow authenticated users to INSERT products (for admin)
CREATE POLICY "Allow authenticated to insert products"
ON products FOR INSERT
TO authenticated
WITH CHECK (true);

-- Policy: Allow authenticated users to UPDATE products (for admin)
CREATE POLICY "Allow authenticated to update products"
ON products FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Policy: Allow authenticated users to DELETE products (for admin)
CREATE POLICY "Allow authenticated to delete products"
ON products FOR DELETE
TO authenticated
USING (true);
```

### Step 3: Add Policies for Orders Table

```sql
-- Enable RLS on orders table (if not already enabled)
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Policy: Allow users to read their own orders
CREATE POLICY "Users can read own orders"
ON orders FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Policy: Allow users to insert their own orders
CREATE POLICY "Users can insert own orders"
ON orders FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Policy: Allow authenticated users to UPDATE any order (for admin)
CREATE POLICY "Allow authenticated to update orders"
ON orders FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Policy: Allow authenticated users to DELETE any order (for admin)
CREATE POLICY "Allow authenticated to delete orders"
ON orders FOR DELETE
TO authenticated
USING (true);
```

### Step 4: Add Policies for Order Items Table

```sql
-- Enable RLS on order_items table
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Policy: Allow reading order items for orders user owns
CREATE POLICY "Users can read own order items"
ON order_items FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM orders
    WHERE orders.id = order_items.order_id
    AND orders.user_id = auth.uid()
  )
);

-- Policy: Allow inserting order items
CREATE POLICY "Allow authenticated to insert order items"
ON order_items FOR INSERT
TO authenticated
WITH CHECK (true);

-- Policy: Allow deleting order items (for admin)
CREATE POLICY "Allow authenticated to delete order items"
ON order_items FOR DELETE
TO authenticated
USING (true);
```

### Step 5: Add Policies for Categories Table

```sql
-- Enable RLS on categories table
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Policy: Allow everyone to read categories
CREATE POLICY "Allow public to read categories"
ON categories FOR SELECT
TO authenticated, anon
USING (true);

-- Policy: Allow authenticated to manage categories (for admin)
CREATE POLICY "Allow authenticated to insert categories"
ON categories FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Allow authenticated to update categories"
ON categories FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Allow authenticated to delete categories"
ON categories FOR DELETE
TO authenticated
USING (true);
```

### Step 6: Add Policies for Cart Items Table

```sql
-- Enable RLS on cart_items table
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own cart items
CREATE POLICY "Users can read own cart items"
ON cart_items FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Policy: Users can insert their own cart items
CREATE POLICY "Users can insert own cart items"
ON cart_items FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own cart items
CREATE POLICY "Users can update own cart items"
ON cart_items FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own cart items
CREATE POLICY "Users can delete own cart items"
ON cart_items FOR DELETE
TO authenticated
USING (auth.uid() = user_id);
```

### Step 7: Add Policies for Profiles Table

```sql
-- Enable RLS on profiles table
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own profile
CREATE POLICY "Users can read own profile"
ON profiles FOR SELECT
TO authenticated
USING (auth.uid() = id);

-- Policy: Users can insert their own profile
CREATE POLICY "Users can insert own profile"
ON profiles FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);

-- Policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);
```

## Alternative: Disable RLS Temporarily (NOT RECOMMENDED FOR PRODUCTION)

If you want to test without RLS (only for development):

```sql
-- Disable RLS on all tables (DEVELOPMENT ONLY)
ALTER TABLE products DISABLE ROW LEVEL SECURITY;
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE order_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE categories DISABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
```

## Verification

After adding policies, test:
1. ✅ Add a new product from admin panel
2. ✅ Edit an existing product
3. ✅ Delete a product
4. ✅ Update order status
5. ✅ Filter products by category

## Notes

- These policies allow all authenticated users to perform admin operations
- For better security, create an `is_admin` flag in the profiles table and check it in policies
- Example: `USING (auth.uid() IN (SELECT id FROM profiles WHERE is_admin = true))`
- RLS is important for production - don't disable it!

## Category Listing Issue

If you're only seeing 2 categories, check:
1. How many categories exist in your database: `SELECT * FROM categories;`
2. Whether the unique filtering is removing some categories
3. Add more categories if needed

To add categories via SQL:
```sql
INSERT INTO categories (name, type, icon) VALUES
  ('Electronics', 'electronics', 'devices'),
  ('Clothing', 'clothing', 'checkroom'),
  ('Home & Garden', 'home-garden', 'home'),
  ('Beauty', 'beauty', 'spa'),
  ('Sports', 'sports', 'sports_soccer');
```
