import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const read = (relative: string) => readFileSync(fileURLToPath(new URL(relative, import.meta.url)), 'utf8');
const core = read('../../sql/task_db_04d_b/001_additive_core_candidate.sql');
const role = read('../../sql/task_db_04d_b3/backend_role_access_candidate.sql');
const patch = read('../../sql/task_db_04d_b7/order_item_lock_role_patch_candidate.sql');
const optional = read('../../sql/task_db_04d_b/002_reserved_limit_optional_candidate.sql');

describe('B7 candidate SQL static checks only (not SQL execution)', () => {
  it('keeps first release additive and 002 optional', () => {
    expect(core.match(/CREATE TABLE public\./g)).toHaveLength(2);
    expect(core).toMatch(/CREATE TABLE public\.stock_ledger/);
    expect(core).toMatch(/CREATE TABLE public\.idempotency_keys/);
    expect(core).not.toMatch(/\bDROP TABLE\b/i);
    expect(core).not.toMatch(/\bCREATE TABLE public\.(?:profiles|products|locations|inventory_items|warehouse_orders|warehouse_order_items)\b/i);
    expect(optional).toMatch(/CHECK \(quantity_reserved <= quantity_on_hand\) NOT VALID/);
  });
  it('identifies the missing B6 order-line lock privilege as a staging patch', () => {
    expect(role).toMatch(/public\.warehouse_orders, public\.warehouse_order_items TO wms_backend/);
    expect(role).not.toMatch(/GRANT UPDATE[^;]*ON public\.warehouse_order_items TO wms_backend/s);
    expect(patch).toMatch(/GRANT UPDATE \(actual_quantity\) ON public\.warehouse_order_items TO wms_backend/);
    expect(patch).toMatch(/CREATE POLICY wms_backend_lock_order_items/);
    expect(patch).not.toMatch(/\bDROP\s+(?:TABLE|POLICY|FUNCTION)\b/i);
  });
});
