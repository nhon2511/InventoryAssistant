-- Requires the reviewed backend-access fragment to be merged into canonical 001.
BEGIN READ ONLY;
SET LOCAL statement_timeout = '15s';
DO $$
DECLARE
  client_role text;
  table_name text;
  privilege_name text;
BEGIN
  IF to_regclass('public.stock_ledger') IS NULL
     OR to_regclass('public.idempotency_keys') IS NULL
     OR NOT EXISTS (SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = 'warehouse_orders'
                      AND column_name = 'approved_by')
     OR NOT EXISTS (SELECT 1 FROM pg_roles
                    WHERE rolname = 'wms_backend' AND rolcanlogin
                      AND NOT rolsuper AND NOT rolbypassrls
                      AND NOT rolcreatedb AND NOT rolcreaterole AND NOT rolinherit) THEN
    RAISE EXCEPTION 'required object or backend role missing';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_class c WHERE c.oid IN
      ('public.stock_ledger'::regclass, 'public.idempotency_keys'::regclass)
      AND NOT c.relrowsecurity
  ) THEN
    RAISE EXCEPTION 'internal table RLS disabled';
  END IF;
  FOREACH client_role IN ARRAY ARRAY['anon','authenticated','service_role'] LOOP
    FOREACH table_name IN ARRAY ARRAY['stock_ledger','idempotency_keys'] LOOP
      FOREACH privilege_name IN ARRAY ARRAY['SELECT','INSERT','UPDATE','DELETE','TRUNCATE'] LOOP
        IF has_table_privilege(client_role, 'public.' || table_name, privilege_name) THEN
          RAISE EXCEPTION 'client privilege regression: % % %',
            client_role, table_name, privilege_name;
        END IF;
      END LOOP;
    END LOOP;
  END LOOP;
  IF has_table_privilege('wms_backend', 'public.stock_ledger', 'UPDATE')
     OR has_table_privilege('wms_backend', 'public.stock_ledger', 'DELETE')
     OR has_table_privilege('wms_backend', 'public.stock_ledger', 'TRUNCATE')
     OR NOT has_table_privilege('wms_backend', 'public.stock_ledger', 'INSERT')
     OR NOT has_table_privilege('wms_backend', 'public.idempotency_keys', 'SELECT') THEN
    RAISE EXCEPTION 'effective table privilege regression';
  END IF;
  IF (SELECT count(*) FROM pg_trigger WHERE tgrelid = 'public.stock_ledger'::regclass
       AND tgname IN ('stock_ledger_append_only','stock_ledger_no_truncate')
       AND tgenabled <> 'D') <> 2
     OR NOT EXISTS (SELECT 1 FROM pg_trigger
                    WHERE tgrelid = 'public.warehouse_orders'::regclass
                      AND tgname = 'warehouse_orders_approval_guard'
                      AND tgenabled <> 'D') THEN
    RAISE EXCEPTION 'required trigger missing/disabled';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_policies
             WHERE schemaname = 'public'
               AND tablename IN ('stock_ledger','idempotency_keys')
               AND EXISTS (SELECT 1 FROM unnest(roles) AS role_name
                           WHERE role_name::text IN ('public','anon','authenticated'))) THEN
    RAISE EXCEPTION 'client policy on internal table';
  END IF;
  IF has_function_privilege('anon', 'public.guard_warehouse_order_approval()', 'EXECUTE')
     OR has_function_privilege('authenticated', 'public.guard_warehouse_order_approval()', 'EXECUTE')
     OR has_function_privilege('anon', 'public.reject_stock_ledger_mutation()', 'EXECUTE')
     OR has_function_privilege('authenticated', 'public.reject_stock_ledger_mutation()', 'EXECUTE') THEN
    RAISE EXCEPTION 'client EXECUTE grant on guard function';
  END IF;
END;
$$;
ROLLBACK;
