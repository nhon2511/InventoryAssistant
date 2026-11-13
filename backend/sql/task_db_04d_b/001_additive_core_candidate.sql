-- STAGING CANDIDATE ONLY. Never run directly or alongside the five untracked files.
-- Requires a separately approved Supabase migration version and verified PG17 backup.
BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';

-- Fail closed on a changed baseline; no IF NOT EXISTS masks drift.
DO $$
BEGIN
  IF to_regclass('public.stock_ledger') IS NOT NULL
     OR to_regclass('public.idempotency_keys') IS NOT NULL
     OR EXISTS (SELECT 1 FROM information_schema.columns
                WHERE table_schema = 'public' AND table_name = 'warehouse_orders'
                  AND column_name = 'approved_by') THEN
    RAISE EXCEPTION 'DB-04D-B baseline drift: target object already exists';
  END IF;
  IF to_regclass('auth.users') IS NULL
     OR to_regclass('public.inventory_items') IS NULL
     OR to_regclass('public.products') IS NULL
     OR to_regclass('public.locations') IS NULL
     OR to_regclass('public.warehouse_orders') IS NULL THEN
    RAISE EXCEPTION 'DB-04D-B baseline dependency missing';
  END IF;
END;
$$;

CREATE TABLE public.stock_ledger (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  inventory_item_id uuid NOT NULL REFERENCES public.inventory_items(id) ON DELETE RESTRICT,
  transaction_type text NOT NULL
    CHECK (transaction_type IN ('INBOUND', 'OUTBOUND', 'ADJUSTMENT', 'TRANSFER')),
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
  location_id uuid NOT NULL REFERENCES public.locations(id) ON DELETE RESTRICT,
  delta integer NOT NULL CHECK (delta <> 0),
  balance integer NOT NULL CHECK (balance >= 0),
  order_id uuid REFERENCES public.warehouse_orders(id) ON DELETE RESTRICT,
  -- Immutable actor UUID: auth.users may be deleted without rewriting audit rows.
  -- NestJS must verify the JWT subject and supply this value; no physical FK.
  created_by uuid,
  note text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX stock_ledger_item_history_idx
  ON public.stock_ledger (inventory_item_id, created_at DESC, id DESC);
CREATE INDEX stock_ledger_product_location_history_idx
  ON public.stock_ledger (product_id, location_id, created_at DESC, id DESC);
CREATE INDEX stock_ledger_order_id_idx ON public.stock_ledger (order_id);

CREATE FUNCTION public.reject_stock_ledger_mutation() RETURNS trigger
LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  RAISE EXCEPTION 'stock_ledger is append-only';
END;
$$;
REVOKE ALL ON FUNCTION public.reject_stock_ledger_mutation() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.reject_stock_ledger_mutation() FROM anon, authenticated, service_role;
CREATE TRIGGER stock_ledger_append_only
  BEFORE UPDATE OR DELETE ON public.stock_ledger
  FOR EACH ROW EXECUTE FUNCTION public.reject_stock_ledger_mutation();
CREATE TRIGGER stock_ledger_no_truncate
  BEFORE TRUNCATE ON public.stock_ledger
  FOR EACH STATEMENT EXECUTE FUNCTION public.reject_stock_ledger_mutation();

CREATE TABLE public.idempotency_keys (
  scope_id uuid NOT NULL,
  key text NOT NULL CHECK (length(key) BETWEEN 1 AND 200),
  http_method text NOT NULL CHECK (http_method IN ('POST', 'PUT', 'PATCH', 'DELETE')),
  request_path text NOT NULL CHECK (length(request_path) BETWEEN 1 AND 2048),
  request_hash char(64) NOT NULL CHECK (request_hash ~ '^[0-9a-f]{64}$'),
  processing_status text NOT NULL DEFAULT 'processing'
    CHECK (processing_status IN ('processing', 'completed')),
  status_code integer CHECK (status_code BETWEEN 100 AND 599),
  response jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL,
  CONSTRAINT idempotency_keys_pkey PRIMARY KEY (scope_id, key),
  CONSTRAINT idempotency_keys_completion_check CHECK (
    (processing_status = 'processing' AND status_code IS NULL AND response IS NULL)
    OR (processing_status = 'completed' AND status_code IS NOT NULL)
  ),
  CONSTRAINT idempotency_keys_expiry_check CHECK (expires_at > created_at)
);
CREATE INDEX idempotency_keys_expires_at_idx ON public.idempotency_keys (expires_at);

ALTER TABLE public.warehouse_orders ADD COLUMN approved_by uuid;
ALTER TABLE public.warehouse_orders ADD CONSTRAINT warehouse_orders_approved_by_fkey
  FOREIGN KEY (approved_by) REFERENCES auth.users(id) ON DELETE SET NULL;
CREATE INDEX warehouse_orders_approved_by_idx
  ON public.warehouse_orders (approved_by) WHERE approved_by IS NOT NULL;

-- Existing authenticated policy/grants permit broad order writes. Protect the
-- new approval column without changing legacy policies or workflow statuses.
CREATE FUNCTION public.guard_warehouse_order_approval() RETURNS trigger
LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  IF current_user IN ('anon', 'authenticated') THEN
    IF TG_OP = 'INSERT' AND NEW.approved_by IS NOT NULL THEN
      RAISE EXCEPTION 'direct approval change is not permitted';
    ELSIF TG_OP = 'UPDATE' THEN
      IF NEW.approved_by IS DISTINCT FROM OLD.approved_by THEN
        RAISE EXCEPTION 'direct approval change is not permitted';
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.guard_warehouse_order_approval() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.guard_warehouse_order_approval() FROM anon, authenticated, service_role;
CREATE TRIGGER warehouse_orders_approval_guard
  BEFORE INSERT OR UPDATE OF approved_by ON public.warehouse_orders
  FOR EACH ROW EXECUTE FUNCTION public.guard_warehouse_order_approval();

ALTER TABLE public.stock_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.idempotency_keys ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.stock_ledger, public.idempotency_keys FROM PUBLIC;
REVOKE ALL ON public.stock_ledger, public.idempotency_keys FROM anon, authenticated;
REVOKE ALL ON public.stock_ledger, public.idempotency_keys FROM service_role;
-- No client policies or backend grants. Dedicated backend role requires a
-- separately reviewed privilege migration; service_role bypass must stay server-side.
COMMIT;
