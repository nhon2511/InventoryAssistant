-- OFFLINE REVIEW FRAGMENT. Not a standalone release migration.
-- After Owner approval, merge the reviewed statements into ONE canonical 001
-- after both tables/approved_by exist and before its COMMIT. No password here.
-- The LOGIN role has no password until provisioned securely by an operator.
DO $$
DECLARE
  table_name text;
  client_role text;
  privilege_name text;
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'wms_backend') THEN
    RAISE EXCEPTION 'wms_backend already exists: inspect role and stop';
  END IF;
  IF to_regclass('public.stock_ledger') IS NULL
     OR to_regclass('public.idempotency_keys') IS NULL
     OR to_regclass('public.warehouse_orders') IS NULL
     OR NOT EXISTS (SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'public' AND table_name = 'warehouse_orders'
                      AND column_name = 'approved_by') THEN
    RAISE EXCEPTION '001 object prerequisites are missing';
  END IF;
  FOREACH table_name IN ARRAY ARRAY[
    'profiles','products','locations','inventory_items',
    'warehouse_orders','warehouse_order_items','stock_ledger','idempotency_keys'
  ] LOOP
    IF NOT EXISTS (
      SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public' AND c.relname = table_name
        AND c.relkind = 'r' AND c.relrowsecurity
    ) THEN
      RAISE EXCEPTION 'required public table/RLS missing: %', table_name;
    END IF;
  END LOOP;
  FOREACH client_role IN ARRAY ARRAY['anon','authenticated','service_role'] LOOP
    FOREACH table_name IN ARRAY ARRAY['stock_ledger','idempotency_keys'] LOOP
      FOREACH privilege_name IN ARRAY ARRAY['SELECT','INSERT','UPDATE','DELETE','TRUNCATE'] LOOP
        IF has_table_privilege(client_role, 'public.' || table_name, privilege_name) THEN
          RAISE EXCEPTION 'default/client privilege on internal table: % % %',
            client_role, table_name, privilege_name;
        END IF;
      END LOOP;
    END LOOP;
  END LOOP;
END;
$$;

CREATE ROLE wms_backend LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE
  NOINHERIT NOREPLICATION NOBYPASSRLS;
GRANT USAGE ON SCHEMA public TO wms_backend;

-- Runtime reads. Profile access is limited to authorization fields.
GRANT SELECT (id, role) ON public.profiles TO wms_backend;
GRANT SELECT ON public.products, public.locations, public.inventory_items,
  public.warehouse_orders, public.warehouse_order_items TO wms_backend;
GRANT UPDATE (quantity_on_hand, quantity_reserved, updated_at)
  ON public.inventory_items TO wms_backend;
GRANT UPDATE (status, approved_by, updated_at)
  ON public.warehouse_orders TO wms_backend;
GRANT SELECT, INSERT ON public.stock_ledger TO wms_backend;
GRANT SELECT ON public.idempotency_keys TO wms_backend;
GRANT INSERT (scope_id, key, http_method, request_path, request_hash, expires_at)
  ON public.idempotency_keys TO wms_backend;
GRANT UPDATE (processing_status, status_code, response, updated_at)
  ON public.idempotency_keys TO wms_backend;
-- No DELETE/TRUNCATE on either internal table. TTL cleanup is a separate design.

-- This trusted backend role has cross-row access; NestJS must authorize each
-- principal and scope. Existing Flutter policies remain untouched.
CREATE POLICY wms_backend_read ON public.profiles
  FOR SELECT TO wms_backend USING (true);
CREATE POLICY wms_backend_read ON public.products
  FOR SELECT TO wms_backend USING (true);
CREATE POLICY wms_backend_read ON public.locations
  FOR SELECT TO wms_backend USING (true);
CREATE POLICY wms_backend_read ON public.inventory_items
  FOR SELECT TO wms_backend USING (true);
CREATE POLICY wms_backend_update ON public.inventory_items
  FOR UPDATE TO wms_backend USING (true) WITH CHECK (true);
CREATE POLICY wms_backend_read ON public.warehouse_orders
  FOR SELECT TO wms_backend USING (true);
CREATE POLICY wms_backend_update ON public.warehouse_orders
  FOR UPDATE TO wms_backend USING (true) WITH CHECK (true);
CREATE POLICY wms_backend_read ON public.warehouse_order_items
  FOR SELECT TO wms_backend USING (true);
CREATE POLICY wms_backend_read ON public.stock_ledger
  FOR SELECT TO wms_backend USING (true);
CREATE POLICY wms_backend_insert ON public.stock_ledger
  FOR INSERT TO wms_backend WITH CHECK (true);
CREATE POLICY wms_backend_read ON public.idempotency_keys
  FOR SELECT TO wms_backend USING (true);
CREATE POLICY wms_backend_insert ON public.idempotency_keys
  FOR INSERT TO wms_backend WITH CHECK (true);
CREATE POLICY wms_backend_update ON public.idempotency_keys
  FOR UPDATE TO wms_backend USING (true) WITH CHECK (true);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = 'wms_backend' AND rolcanlogin
      AND NOT rolbypassrls AND NOT rolsuper AND NOT rolcreaterole
  ) OR NOT has_table_privilege('wms_backend', 'public.stock_ledger', 'INSERT')
    OR has_table_privilege('wms_backend', 'public.stock_ledger', 'UPDATE')
    OR has_table_privilege('wms_backend', 'public.stock_ledger', 'DELETE')
    OR has_table_privilege('wms_backend', 'public.idempotency_keys', 'DELETE') THEN
    RAISE EXCEPTION 'backend role privilege postcondition failed';
  END IF;
END;
$$;
