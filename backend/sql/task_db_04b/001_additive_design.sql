-- OFFLINE DESIGN ONLY. Do not apply to Supabase Cloud in TASK-DB-04B.
-- Apply once through the chosen Supabase migration history after owner review.
-- Existing six business tables are prerequisites; this script never creates them.
BEGIN;

CREATE TABLE public.stock_ledger (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_type text NOT NULL CHECK (transaction_type IN ('INBOUND', 'OUTBOUND', 'ADJUSTMENT', 'TRANSFER')),
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
  location_id uuid NOT NULL REFERENCES public.locations(id) ON DELETE RESTRICT,
  delta integer NOT NULL CHECK (delta <> 0),
  balance integer NOT NULL CHECK (balance >= 0),
  order_id uuid REFERENCES public.warehouse_orders(id) ON DELETE RESTRICT,
  created_by uuid REFERENCES public.profiles(id) ON DELETE RESTRICT,
  note text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX stock_ledger_product_location_created_idx
  ON public.stock_ledger (product_id, location_id, created_at DESC, id DESC);
CREATE INDEX stock_ledger_product_id_idx ON public.stock_ledger (product_id);
CREATE INDEX stock_ledger_order_id_idx ON public.stock_ledger (order_id);
CREATE INDEX stock_ledger_location_id_idx ON public.stock_ledger (location_id);
CREATE INDEX stock_ledger_created_at_idx ON public.stock_ledger (created_at DESC);

-- Defense in depth against accidental mutation by table writers.
CREATE FUNCTION public.reject_stock_ledger_mutation() RETURNS trigger
LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
  RAISE EXCEPTION 'stock_ledger is append-only';
END;
$$;
REVOKE ALL ON FUNCTION public.reject_stock_ledger_mutation() FROM PUBLIC, anon, authenticated;
CREATE TRIGGER stock_ledger_append_only
  BEFORE UPDATE OR DELETE ON public.stock_ledger
  FOR EACH ROW EXECUTE FUNCTION public.reject_stock_ledger_mutation();

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

-- Nullable column preserves every existing order and the Flutter approved_by DTO.
ALTER TABLE public.warehouse_orders ADD COLUMN approved_by uuid;
ALTER TABLE public.warehouse_orders ADD CONSTRAINT warehouse_orders_approved_by_fkey
  FOREIGN KEY (approved_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
CREATE INDEX warehouse_orders_approved_by_idx ON public.warehouse_orders (approved_by);

-- RLS plus explicit grants: new public tables must not inherit broad API access.
ALTER TABLE public.stock_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.idempotency_keys ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.stock_ledger, public.idempotency_keys FROM PUBLIC;
REVOKE ALL ON public.stock_ledger, public.idempotency_keys FROM anon, authenticated;
-- No client policies. A dedicated backend DB role may later receive only
-- SELECT/INSERT on stock_ledger and SELECT/INSERT/UPDATE/DELETE on keys.
-- Backend role and credentials must be approved and tested before deployment.

COMMIT;
