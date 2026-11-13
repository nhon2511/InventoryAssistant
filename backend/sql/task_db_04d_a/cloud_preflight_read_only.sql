-- TASK-DB-04D-A. Run only after the operator verifies the Development project
-- reference, endpoint, TLS, and credentials outside this file.
-- psql -X -v ON_ERROR_STOP=1 -f cloud_preflight_read_only.sql
\pset pager off
\timing off
\set ON_ERROR_STOP on
BEGIN TRANSACTION READ ONLY;
SET LOCAL statement_timeout = '10s';
SET LOCAL lock_timeout = '3s';

\echo 01_connection
SELECT current_database() AS database_name,
       current_setting('server_version') AS server_version,
       COALESCE((SELECT ssl FROM pg_stat_ssl WHERE pid = pg_backend_pid()), false) AS database_backend_ssl;

\echo 02_public_tables
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;

\echo 03_business_columns
SELECT table_name, column_name, udt_name, is_nullable,
       (column_default IS NOT NULL) AS has_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('profiles', 'products', 'locations', 'inventory_items',
                     'warehouse_orders', 'warehouse_order_items')
ORDER BY table_name, ordinal_position;

\echo 04_constraints
SELECT c.conrelid::regclass::text AS table_name, c.conname, c.contype,
       CASE WHEN c.contype = 'f' THEN c.confrelid::regclass::text END AS referenced_table,
       CASE WHEN c.contype = 'f' THEN c.confdeltype END AS delete_action,
       c.convalidated,
       ARRAY(SELECT a.attname FROM pg_attribute a
             WHERE a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
             ORDER BY array_position(c.conkey, a.attnum)) AS columns
FROM pg_constraint c
JOIN pg_namespace n ON n.oid = c.connamespace
JOIN pg_class r ON r.oid = c.conrelid
WHERE n.nspname = 'public'
  AND r.relname IN
      ('profiles', 'products', 'locations', 'inventory_items',
       'warehouse_orders', 'warehouse_order_items')
ORDER BY table_name, c.conname;

\echo 05_indexes
SELECT t.relname AS table_name, i.relname AS index_name,
       x.indisprimary, x.indisunique,
       (x.indpred IS NOT NULL) AS is_partial,
       md5(pg_get_indexdef(x.indexrelid)) AS definition_digest
FROM pg_index x
JOIN pg_class t ON t.oid = x.indrelid
JOIN pg_class i ON i.oid = x.indexrelid
JOIN pg_namespace n ON n.oid = t.relnamespace
WHERE n.nspname = 'public'
  AND t.relname IN ('profiles', 'products', 'locations', 'inventory_items',
                    'warehouse_orders', 'warehouse_order_items')
ORDER BY t.relname, i.relname;

\echo 06_new_objects
SELECT to_regclass('public.stock_ledger') IS NOT NULL AS stock_ledger_exists,
       to_regclass('public.idempotency_keys') IS NOT NULL AS idempotency_keys_exists,
       EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema = 'public' AND table_name = 'warehouse_orders'
                 AND column_name = 'approved_by') AS approved_by_exists;

\echo 07_rls
SELECT c.relname AS table_name, c.relrowsecurity, c.relforcerowsecurity
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relkind IN ('r', 'p')
ORDER BY c.relname;

\echo 08_policies
SELECT tablename, policyname, roles, cmd, permissive,
       (qual = 'true') AS using_true,
       (with_check = 'true') AS check_true,
       md5(COALESCE(qual, '')) AS using_digest,
       md5(COALESCE(with_check, '')) AS check_digest
FROM pg_policies WHERE schemaname = 'public'
ORDER BY tablename, policyname;

\echo 09_table_grants
SELECT table_name, grantee,
       string_agg(privilege_type, ',' ORDER BY privilege_type) AS privileges
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND grantee IN ('anon', 'authenticated', 'service_role')
GROUP BY table_name, grantee ORDER BY table_name, grantee;
SELECT n.nspname AS schema_name, d.defaclobjtype AS object_type,
       count(*) AS default_acl_entries
FROM pg_default_acl d JOIN pg_namespace n ON n.oid = d.defaclnamespace
WHERE n.nspname = 'public'
GROUP BY n.nspname, d.defaclobjtype ORDER BY object_type;

\echo 10_functions_triggers_extensions
SELECT n.nspname AS schema_name, p.proname AS function_name, p.prosecdef AS security_definer
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
ORDER BY p.proname;
SELECT t.tgrelid::regclass::text AS table_name, t.tgname AS trigger_name,
       t.tgenabled AS enabled
FROM pg_trigger t JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND NOT t.tgisinternal
ORDER BY table_name, t.tgname;
SELECT e.extname, e.extversion, n.nspname AS extension_schema
FROM pg_extension e JOIN pg_namespace n ON n.oid = e.extnamespace
ORDER BY e.extname;

\echo 11_migration_history
SELECT (to_regclass('supabase_migrations.schema_migrations') IS NOT NULL) AS history_exists;
SELECT (to_regclass('supabase_migrations.schema_migrations') IS NOT NULL) AS has_history
\gset
\if :has_history
SELECT version FROM supabase_migrations.schema_migrations ORDER BY version;
\endif

\echo 12_inventory_aggregates
WITH duplicate_null_lots AS (
  SELECT product_id, location_id FROM public.inventory_items
  WHERE lot_number IS NULL GROUP BY product_id, location_id HAVING count(*) > 1
)
SELECT count(*) AS duplicate_null_lot_slots FROM duplicate_null_lots;
SELECT count(*) FILTER (WHERE quantity_on_hand < 0) AS negative_on_hand,
       count(*) FILTER (WHERE quantity_reserved < 0) AS negative_reserved,
       count(*) FILTER (WHERE quantity_reserved > quantity_on_hand) AS over_reserved
FROM public.inventory_items;

ROLLBACK;
