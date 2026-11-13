-- STAGING CANDIDATE ONLY. Independent approval after every inventory write path
-- (including public.confirm_outbound_order RPC) has been audited for this rule.
BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';
DO $$
BEGIN
  IF to_regclass('public.inventory_items') IS NULL OR EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.inventory_items'::regclass
      AND conname = 'inventory_reserved_within_on_hand'
  ) THEN
    RAISE EXCEPTION 'DB-04D-B inventory constraint baseline drift';
  END IF;
END;
$$;
ALTER TABLE public.inventory_items
  ADD CONSTRAINT inventory_reserved_within_on_hand
  CHECK (quantity_reserved <= quantity_on_hand) NOT VALID;
COMMIT;
-- VALIDATE CONSTRAINT is a separate, approved operation after write-path checks.
