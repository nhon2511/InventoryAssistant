-- Execute only against an approved isolated local clone, never Cloud in this task.
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_name IN
  ('profiles', 'products', 'locations', 'inventory_items',
   'warehouse_orders', 'warehouse_order_items', 'stock_ledger', 'idempotency_keys')
ORDER BY table_name;

SELECT product_id, location_id, count(*) AS duplicate_null_lots
FROM public.inventory_items WHERE lot_number IS NULL
GROUP BY product_id, location_id HAVING count(*) > 1;

SELECT count(*) FILTER (WHERE quantity_on_hand < 0) AS negative_on_hand,
       count(*) FILTER (WHERE quantity_reserved < 0) AS negative_reserved,
       count(*) FILTER (WHERE quantity_reserved > quantity_on_hand) AS over_reserved
FROM public.inventory_items;
