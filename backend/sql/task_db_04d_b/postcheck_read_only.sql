-- Run only after a separately approved deployment. No DML/DDL.
BEGIN READ ONLY;
SET LOCAL statement_timeout = '15s';
SELECT c.relname, c.relrowsecurity, c.relforcerowsecurity
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relname IN ('stock_ledger','idempotency_keys')
ORDER BY c.relname;
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns WHERE table_schema = 'public'
  AND ((table_name = 'warehouse_orders' AND column_name = 'approved_by')
    OR table_name IN ('stock_ledger','idempotency_keys'))
ORDER BY table_name, ordinal_position;
SELECT conrelid::regclass::text AS table_name, conname, contype,
       pg_get_constraintdef(oid) AS definition, convalidated
FROM pg_constraint WHERE conrelid IN
  ('public.stock_ledger'::regclass,'public.idempotency_keys'::regclass,
   'public.warehouse_orders'::regclass,'public.inventory_items'::regclass)
ORDER BY 1, 2;
SELECT schemaname, tablename, indexname, indexdef FROM pg_indexes
WHERE schemaname = 'public' AND tablename IN
  ('stock_ledger','idempotency_keys','warehouse_orders') ORDER BY 2, 3;
SELECT tgname, pg_get_triggerdef(oid) AS definition FROM pg_trigger
WHERE tgrelid = 'public.stock_ledger'::regclass AND NOT tgisinternal ORDER BY tgname;
SELECT schemaname, tablename, policyname, roles, cmd FROM pg_policies
WHERE schemaname = 'public' AND tablename IN ('stock_ledger','idempotency_keys');
SELECT grantee, table_name, privilege_type FROM information_schema.table_privileges
WHERE table_schema = 'public' AND table_name IN ('stock_ledger','idempotency_keys')
  AND grantee IN ('anon','authenticated','service_role','PUBLIC') ORDER BY 1, 2, 3;
COMMIT;
