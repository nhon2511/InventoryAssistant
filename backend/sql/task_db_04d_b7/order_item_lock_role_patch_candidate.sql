-- STAGING FRAGMENT ONLY. DO NOT RUN. Merge into the ONE approved canonical 001
-- after B3's backend role fragment and before its COMMIT, if B6 row locking stays.
-- PostgreSQL 17 SELECT ... FOR UPDATE needs UPDATE privilege on at least one
-- selected table column and an applicable UPDATE RLS policy.
-- This grants the runtime role ability to change actual_quantity; Owner must
-- approve that privilege and ensure the role credential remains backend-only.
GRANT UPDATE (actual_quantity) ON public.warehouse_order_items TO wms_backend;
CREATE POLICY wms_backend_lock_order_items ON public.warehouse_order_items
  FOR UPDATE TO wms_backend USING (true) WITH CHECK (true);
