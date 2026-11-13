-- OFFLINE DESIGN ONLY. Optional follow-up after read-only violation audit.
-- Do not apply automatically with 001; owner approval and local data test required.
BEGIN;
ALTER TABLE public.inventory_items
  ADD CONSTRAINT inventory_on_hand_nonnegative CHECK (quantity_on_hand >= 0) NOT VALID,
  ADD CONSTRAINT inventory_reserved_nonnegative CHECK (quantity_reserved >= 0) NOT VALID,
  ADD CONSTRAINT inventory_reserved_within_on_hand CHECK (quantity_reserved <= quantity_on_hand) NOT VALID;
-- Later, after repairing any legacy violations in a separately approved task:
-- ALTER TABLE public.inventory_items VALIDATE CONSTRAINT inventory_on_hand_nonnegative;
-- ALTER TABLE public.inventory_items VALIDATE CONSTRAINT inventory_reserved_nonnegative;
-- ALTER TABLE public.inventory_items VALIDATE CONSTRAINT inventory_reserved_within_on_hand;
COMMIT;
