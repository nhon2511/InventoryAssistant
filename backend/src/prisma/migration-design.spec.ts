import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const sql = readFileSync(
  fileURLToPath(new URL('../../sql/task_db_04b/001_additive_design.sql', import.meta.url)),
  'utf8',
);
const inventoryChecks = readFileSync(
  fileURLToPath(
    new URL('../../sql/task_db_04b/002_inventory_checks_optional.sql', import.meta.url),
  ),
  'utf8',
);

describe('TASK-DB-04B offline migration guard', () => {
  it('only creates additive tables and preserves six baseline tables', () => {
    expect(sql.match(/CREATE TABLE\s+public\./gi)).toHaveLength(2);
    expect(sql).not.toMatch(/\bDROP\s+TABLE\b/i);
    expect(sql).not.toMatch(/\bCREATE\s+TABLE\s+public\.(?:profiles|products|locations|inventory_items|warehouse_orders|warehouse_order_items)\b/i);
    expect(sql).toMatch(/ADD COLUMN approved_by uuid/i);
  });

  it('keeps both new public tables invisible to client roles', () => {
    expect(sql).toMatch(/REVOKE ALL ON public\.stock_ledger, public\.idempotency_keys FROM anon, authenticated/i);
    expect(sql).toMatch(/ALTER TABLE public\.stock_ledger ENABLE ROW LEVEL SECURITY/i);
    expect(sql).toMatch(/ALTER TABLE public\.idempotency_keys ENABLE ROW LEVEL SECURITY/i);
    expect(sql).not.toMatch(/\bCREATE POLICY\b/i);
  });

  it('guards ledger mutation and scoped concurrent idempotency claims', () => {
    expect(sql).toMatch(/BEFORE UPDATE OR DELETE ON public\.stock_ledger/i);
    expect(sql).toMatch(/PRIMARY KEY \(scope_id, key\)/i);
    expect(sql).toMatch(/request_hash char\(64\)/i);
    expect(sql).toMatch(/idempotency_keys_completion_check/i);
  });

  it('keeps inventory checks separately gated and preserves unique semantics', () => {
    expect(sql).not.toMatch(/ALTER TABLE public\.inventory_items/i);
    expect(inventoryChecks).toMatch(/CHECK \(quantity_reserved <= quantity_on_hand\) NOT VALID/i);
    expect(inventoryChecks).not.toMatch(/\b(?:DROP|CREATE)\s+(?:UNIQUE\s+)?INDEX\b/i);
  });
});
