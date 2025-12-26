-- Add shipping fields to orders table
-- Run this in Supabase SQL editor or via CLI

ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS shipping_name text,
  ADD COLUMN IF NOT EXISTS shipping_phone text,
  ADD COLUMN IF NOT EXISTS shipping_address text;

-- Optional: helpful index for querying by phone
CREATE INDEX IF NOT EXISTS idx_orders_shipping_phone
  ON public.orders USING btree (shipping_phone);

-- No policy changes needed if orders already has RLS; 
-- column additions inherit existing policies.
