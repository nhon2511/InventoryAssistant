# Inventory command contract (offline only)

`inventory-command.contract.ts` is pure orchestration behind ports. It is **not** registered as a NestJS provider, has no Prisma adapter, and makes no database call. Passing its unit tests does not make stock movements production ready. Flutter's existing `confirm_outbound_order` RPC and direct writes remain unchanged.

## Micro-tasks and acceptance criteria

1. **Authenticated request contract:** derive `scopeId` and `actorId` from verified server-side identity; canonicalize the actual route/path and finite JSON body, cap body/key sizes, hash with `requestFingerprint`. Never trust client-supplied scope/role. Acceptance: same canonical request hashes identically; changed method/path/body conflicts; no raw body or token stored in keys table.
2. **Idempotency adapter:** implement `claimOrLock` with parameterized `INSERT ... ON CONFLICT DO NOTHING RETURNING` then `SELECT ... FOR UPDATE` in the **same** transaction. Compare hash/method/path and refuse expired-key reuse; define lock wait and retention/cleanup policy. Acceptance: concurrent same-key request executes one side effect, same hash replays, different hash conflicts, timeout/rollback retry is safe, completion updates exactly one row.
3. **Inventory adapter:** implement `lockInventory` as `SELECT ... FOR UPDATE`, verify item/product/location identity, then update inventory and append ledger in one Prisma interactive transaction. Lock multiple item IDs in a stable order. Acceptance: concurrent decrements serialize, negative/over-reserved/overflow values reject, failure at any step rolls back inventory, ledger and claim; ledger balance equals committed inventory state.
4. **Approval authorization:** `assertApproverRole` is only a final pure guard. Source the ADMIN/MANAGER role from a trusted server-side authority. The current `profiles` table has broad authenticated UPDATE according to the schema audit; therefore `profiles.role` alone is **not trusted** until RLS/ACL is hardened. Acceptance: a client cannot self-promote or set `approved_by`, and server verifies actor/role before writing approval; test through real PostgREST role context.
5. **Cutover/audit:** inventory writes through Flutter and `confirm_outbound_order` must be audited before relying on ledger completeness. Do not replace the RPC without Owner approval. Acceptance: every authorized stock mutation has exactly one ledger event and no bypass path; Flutter DTO/approval behavior remains compatible.

`InventoryTransactionPort` is an interface; the in-memory test runner simulates commit/rollback but cannot prove PostgreSQL locking, RLS, grants, FK behavior, or Supabase session pooler compatibility. Those require a separately approved PG17/Cloud Development validation plan.

## TASK-DB-04D-B4 implementation status

- `PrismaInventoryTransactionAdapter` implements the port with one Prisma v6 interactive transaction. It uses parameterized tagged SQL for claim insert/unique conflict, `SELECT ... FOR UPDATE` on a duplicate claim and the inventory item, Prisma update/create for stock and ledger, and a guarded completion update. It sets a transaction-local lock timeout, uses Serializable isolation, caps transaction wait/runtime, and retries only Prisma P2034 or P2010 with SQLSTATE 40001/40P01/55P03 at most three attempts. Each retry starts a new transaction; business errors are not retried. The adapter is **not registered in AppModule**.
- `InventoryCommandService` derives actor/scope only from a `VerifiedPrincipalProvider`; none is implemented or registered. It exposes no route. Its `receive` and `ship` methods prepare positive/negative deltas, respectively. `authorizeApproval` fails closed without a trusted role; `profiles.role` is not a trusted authority under current client-write policy.
- `InventoryWorkflowRepository` and `InventoryWorkflowTransactionPort` reserve interfaces for reservation and order state transitions within the same transaction. There is no implementation because the existing Flutter/RPC workflow has not been audited; no new status transition is enabled.

### B4 acceptance checklist

| Micro-task | Offline acceptance | Remaining gate |
| --- | --- | --- |
| Interactive transaction | All adapter methods receive the same `tx`; timeout and bounded retry unit-tested | PostgreSQL 17 commit/rollback/retry tests |
| Idempotency | Parameterized INSERT conflict, locked duplicate, hash/replay/conflict tests | Concurrent requests and expiry policy on database |
| Stock movement | Lock item before update; signed delta, int4, negative/over-reservation checks; ledger and key completion in same callback | Real FK/RLS/trigger and concurrent stock tests |
| Authorization | Verified-principal interface, no caller-provided actor/scope; approval fails without trusted role | JWT verifier and trusted approval authority |
| Reservation/order | Interface names transaction boundary; no endpoint or write path | Owner-approved workflow and Flutter/RPC cutover |

The mock concurrency test models a unique-key wait, but does not establish actual PostgreSQL or pooler behavior. Never enable the adapter by registering it or exposing endpoints until migration 001, role/ACL verification, a trusted identity provider, recovery plan, and database integration tests are approved.

## TASK-DB-04D-B6 confirmation workflow (offline)

`OrderConfirmationService` and `PrismaOrderConfirmationAdapter` add a separate, unwired confirmation path for existing DRAFT orders. It validates a verified principal with a trusted role and exact creator ownership, claims idempotency, locks the order, loads its lines, locks inventory identities in sorted order, updates balances, appends one ledger row per line, completes the order, and completes the claim in one serializable transaction. A second key cannot confirm a completed order; the same key can replay a small response. The adapter is not registered in AppModule and no confirmation route exists.

This path deliberately requires **exactly one existing inventory item** for each product/location/lot and matching expiry. It rejects missing or ambiguous rows, including duplicate NULL-lot rows; it does not create an inventory item until identity/uniqueness rules and database integration tests are approved. Only DRAFT → COMPLETED is modeled because Flutter's current confirm actions target that state; other statuses remain blocked. Tests use in-memory transaction and SQL-shaped mocks, so they do not prove PostgreSQL atomicity, lock timing, RLS, grants, triggers, or real JWT/DB-role compatibility. See `docs/audits/TASK-DB-04D_B6_WORKFLOW_INTEGRITY.md` for cutover and release gates.
