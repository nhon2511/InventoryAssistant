-- Separate operator review gate; never run on an unverified target.
BEGIN READ ONLY;
SET LOCAL statement_timeout = '15s';
SET LOCAL lock_timeout = '3s';
DO $$
DECLARE
  table_name text;
BEGIN
  IF current_database() <> 'postgres'
     OR current_setting('server_version_num')::integer / 10000 <> 17 THEN
    RAISE EXCEPTION 'wrong database or PostgreSQL major version';
  END IF;
  FOREACH table_name IN ARRAY ARRAY[
    'profiles','products','locations','inventory_items',
    'warehouse_orders','warehouse_order_items','your_table'
  ] LOOP
    IF to_regclass('public.' || table_name) IS NULL THEN
      RAISE EXCEPTION 'baseline table missing: %', table_name;
    END IF;
  END LOOP;
  IF to_regclass('auth.users') IS NULL
     OR to_regclass('public.stock_ledger') IS NOT NULL
     OR to_regclass('public.idempotency_keys') IS NOT NULL
     OR to_regclass('supabase_migrations.schema_migrations') IS NOT NULL
     OR EXISTS (SELECT 1 FROM information_schema.columns
                WHERE table_schema = 'public' AND table_name = 'warehouse_orders'
                  AND column_name = 'approved_by')
     OR EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'wms_backend') THEN
    RAISE EXCEPTION 'baseline object/role drift';
  END IF;
  IF EXISTS (SELECT 1 FROM public.inventory_items
             WHERE quantity_on_hand < 0 OR quantity_reserved < 0
                OR quantity_reserved > quantity_on_hand) THEN
    RAISE EXCEPTION 'inventory quantity violation';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.inventory_items WHERE lot_number IS NULL
    GROUP BY product_id, location_id HAVING count(*) > 1
  ) THEN
    RAISE EXCEPTION 'duplicate NULL-lot slots require review';
  END IF;
END;
$$;
-- History unexpectedly present is a STOP above; inspect separately, never repair here.
SELECT defaclrole::regrole::text AS owner_role, defaclnamespace::regnamespace::text AS schema_name,
       defaclobjtype AS object_type, defaclacl IS NOT NULL AS has_acl
FROM pg_default_acl WHERE defaclnamespace = 'public'::regnamespace
ORDER BY owner_role, object_type;
ROLLBACK;
