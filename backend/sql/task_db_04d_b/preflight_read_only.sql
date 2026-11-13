-- Operator runs only after independently verifying the Development project.
-- Output is metadata and aggregate counts; no row-level business data.
BEGIN READ ONLY;
SET LOCAL statement_timeout = '15s';
SELECT current_database() AS database_name, current_user AS role_name,
       current_setting('server_version') AS pg_version,
       inet_server_addr() AS server_address;
SELECT n.nspname AS schema_name, c.relname AS object_name, c.relkind,
       c.relrowsecurity AS rls_enabled
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relname IN
  ('profiles','products','locations','inventory_items','warehouse_orders',
   'warehouse_order_items','your_table','stock_ledger','idempotency_keys')
ORDER BY c.relname;
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'warehouse_orders'
  AND column_name IN ('created_by','approved_by') ORDER BY column_name;
SELECT conrelid::regclass::text AS table_name, conname, contype,
       pg_get_constraintdef(oid) AS definition
FROM pg_constraint WHERE conrelid IN
  ('public.inventory_items'::regclass,'public.warehouse_orders'::regclass)
ORDER BY 1, 2;
SELECT to_regclass('supabase_migrations.schema_migrations') AS migration_history;
SELECT count(*) AS negative_on_hand FROM public.inventory_items WHERE quantity_on_hand < 0;
SELECT count(*) AS negative_reserved FROM public.inventory_items WHERE quantity_reserved < 0;
SELECT count(*) AS over_reserved FROM public.inventory_items
WHERE quantity_reserved > quantity_on_hand;
SELECT count(*) AS duplicate_null_lot_slots FROM (
  SELECT 1 FROM public.inventory_items WHERE lot_number IS NULL
  GROUP BY product_id, location_id HAVING count(*) > 1
) AS slots;
COMMIT;
