# TASK-DB-04D-B4 — NestJS inventory transaction adapter (offline)

Ngày 13/11/2026. Branch `feature/backend-nestjs-init`, HEAD trước task `3f3a93a`, upstream cùng HEAD. Tracked working tree ban đầu sạch; năm migration chưa track trong `supabase/migrations/` và tài liệu kiến trúc chưa track là tài sản của Owner, giữ nguyên, không stage. Đã đọc AGENTS.md, báo cáo B3, Prisma schema, contract B3, PrismaService, modules/tests và SQL staging. **Không kết nối Supabase Cloud, chạy migration, restore, hoặc bật endpoint.**

## 1. Files changed

| File | Thay đổi |
| --- | --- |
| `backend/src/inventory-contract/inventory-command.contract.ts` | Thêm `transactionType` INBOUND/OUTBOUND và guard dấu delta; truyền loại vào ledger port. |
| `backend/src/inventory-contract/prisma-inventory-transaction.adapter.ts` | Prisma v6 interactive transaction adapter, claim/lock SQL parameterized, Prisma updates/inserts, bounded retry. |
| `backend/src/inventory-contract/inventory-command.service.ts` | Service inbound/outbound và approval guard qua `VerifiedPrincipalProvider`; repository interfaces cho reservation/order transition tương lai. |
| `backend/src/inventory-contract/*.spec.ts` | Mở rộng test contract và thêm adapter/service mocks. |
| `backend/src/inventory-contract/README.md` | Micro-tasks, acceptance criteria, giới hạn vận hành và cutover gates. |
| `docs/audits/TASK-DB-04D_B4_TRANSACTION_ADAPTER.md` | Báo cáo này. |

Không sửa Prisma schema, Flutter, SQL migration candidate hoặc Cloud configuration trong B4.

## 2. Architecture decisions

`PrismaInventoryTransactionAdapter` implements `InventoryTransactionRunner` nhưng **không đăng ký trong AppModule**, không có controller/endpoint. Nó chỉ được gọi khi một component tương lai khởi tạo có chủ đích sau khi migration/role/authorization được duyệt. `InventoryCommandService` nhận runner và `VerifiedPrincipalProvider` qua constructor; không có JWT verifier concrete nào được cung cấp hoặc đăng ký. Service lấy `scopeId` và `actorId` từ kết quả xác minh, không đọc user/role từ request body. `InventoryWorkflowRepository`/transaction port dành cho reservation và order transition; chưa có implementation vì workflow Flutter/RPC hiện hữu chưa được audit.

Thiết kế này giữ chức năng Flutter hiện tại và không thay `confirm_outbound_order`. `receive` chỉ nhận quantity dương và tạo delta dương; `ship` tạo delta âm. Chỉ một đường `executeMovementContract` tính balance và ghi ledger. Không có status transition mới, do đó rollback không thể chuyển phiếu sang COMPLETED trong code B4; kiểm chứng order transition vẫn là task sau.

## 3. Transaction boundary

Mỗi lệnh chạy trong **một** Prisma interactive `$transaction` với `maxWait=2s`, `timeout=10s`, isolation `Serializable`; trong callback dùng cùng `tx` cho mọi thao tác. `SELECT set_config('lock_timeout','3s',true)` đặt timeout chỉ cho transaction đó. Không có nested transaction, network call hoặc token verification trong callback. [Prisma v6 transaction docs](https://www.prisma.io/docs/orm/v6/prisma-client/queries/transactions) mô tả transaction callback, timeout và P2034 retry.

Thứ tự: claim idempotency → nếu key mới, `SELECT inventory_items ... FOR UPDATE` → xác minh item/product/location → guard int4/âm/over-reservation → `inventoryItem.updateMany` (đòi đúng một row) → `stockLedger.create` → `idempotencyKey.updateMany` sang completed (đòi đúng một row) → COMMIT. Bất kỳ throw nào trước COMMIT rollback cả claim, inventory và ledger theo contract Prisma; mock unit chỉ xác nhận orchestration, chưa chứng minh rollback thực DB.

Chỉ retry tối đa ba lần cho `PrismaClientKnownRequestError` P2034 hoặc P2010 có SQLSTATE 40001/40P01/55P03, mỗi lần là transaction mới; lỗi nghiệp vụ, unknown DB errors, timeout khác không retry. Delay 25/50 ms ở hai lần retry. Không retry tùy ý; nếu commit thành công trước phản hồi lỗi mơ hồ, cùng `(scopeId,key)` phải replay theo record persisted, nhưng chưa có DB concurrency test.

## 4. Row lock and SQL safety

`claimOrLock` dùng tagged template `$queryRaw` với `INSERT ... ON CONFLICT (scope_id,key) DO NOTHING RETURNING`, sau conflict mới `SELECT ... FOR UPDATE`; item cũng `SELECT ... FOR UPDATE` theo UUID. Identifier SQL cố định; input chỉ đi qua biến bind của tagged template, không có `$queryRawUnsafe` hoặc ghép SQL từ user input. [Prisma v6 raw query docs](https://www.prisma.io/docs/orm/v6/prisma-client/using-raw-sql/raw-queries) xác nhận tagged templates parameterize giá trị. Row lock chỉ bao phủ đúng inventory item; multi-item lock ordering và transaction tests là task sau.

Adapter kiểm tra row count ở update tồn kho và complete key. Role candidate `wms_backend` B3 cấp SELECT/UPDATE cột cần thiết trên inventory, SELECT/INSERT ledger và SELECT/INSERT claim columns/UPDATE completion columns trên keys; adapter không cần DELETE/TRUNCATE. Cần kiểm tra quyền `SELECT ... FOR UPDATE`, Prisma generated SQL (bao gồm `updated_at`/RETURNING), RLS policy, trigger và Supabase Session Pooler bằng role thực. Hiện `.env` dùng `postgres` theo audit B2/B3; không đổi credential trong B4.

## 5. Idempotency behavior

Scope lấy từ principal đã xác thực, key do caller gửi với độ dài 1–200; body fingerprint chỉ gồm item/product/location/quantity/order/type, không chứa token/password/raw HTTP body. `requestFingerprint` canonicalize JSON; cùng key + hash/method/path completed trả response nhỏ `{inventoryItemId,balance}`, khác hash trả `conflict`, processing trả `in_progress`, expired trả `expired` và **không** tái sử dụng key. Trạng thái processing trong đường mới chưa hiển thị cho transaction khác trước COMMIT; request trùng có thể chờ unique-key lock rồi đọc completed. Lock wait và retry được giới hạn, nhưng timing trên PostgreSQL thật chưa kiểm chứng. TTL cleanup/retention chưa implement; global process mutex không được dùng. Hai key khác nhau vẫn có thể yêu cầu cùng business event, nên chưa có event-level uniqueness guarantee.

## 6. Authorization boundary

`VerifiedPrincipalProvider` là interface, chưa có JWT verifier/trusted authorization provider. Không có endpoint nên không thể truyền body `scopeId`/`actorId` vào đường B4. `authorizeApproval` fail closed nếu thiếu `trustedRole` hoặc role là STAFF; chỉ trả subject để use case tương lai quyết định, **không cập nhật order**. Theo audit, `profiles.role` hiện có thể bị client sửa qua policy rộng nên không được dùng làm trusted role. Cần provider xác minh JWT và nguồn role server-controlled (ví dụ app_metadata được xác minh), đồng thời audit RLS/ACL, trước khi kích hoạt. Client Flutter không có quyền trực tiếp ledger/keys theo SQL candidate; điều này chưa được test trên Cloud.

## 7. Test results

| Gate | Kết quả | Giới hạn |
| --- | --- | --- |
| `npm run prisma:validate` / `npm run prisma:generate` | PASS / PASS | Không kết nối DB |
| `npm run lint` / `npm run build` | PASS / PASS | TypeScript offline |
| `npm run test` | PASS, **57/57** (49 cũ + 8 B4) | Adapter mocks, in-memory transaction; không có PG |
| `npm run test:e2e` | PASS, **5/5** | Mock-only, không có endpoint B4 |
| `git diff --check` / staged diff check | PASS / PASS | Whitespace only |

Các test B4 kiểm tra transaction options, SQL có `FOR UPDATE`/`ON CONFLICT` và không nối user value vào SQL literal, create ledger/update stock/complete key cùng fake `tx`, replay/conflict, bounded retry/classification, ledger error không complete, principal/approval fail-closed và mock concurrent ordering. Test concurrent chỉ mô phỏng unique-key wait bằng promise gate, **không xác minh concurrency PostgreSQL**. B3 test fake rollback vẫn PASS; adapter mock không chứng minh atomicity của DB.

## 8. Runtime limitations

**NOT RUN:** PostgreSQL 17 integration, row-lock timing/deadlock/serialization, actual transaction rollback, FK/RLS/ACL/grants, Supabase Session Pooler login bằng role `wms_backend`, real JWT authorization, HTTP endpoint, Flutter smoke, Cloud schema drift hoặc migration. Cloud chưa có `stock_ledger`, `idempotency_keys`, `approved_by`; gọi adapter lúc này sẽ lỗi. Backup manual chưa restore thử và Supabase Free không có scheduled backups theo Owner. Không tuyên bố production-ready.

## 9. Migration dependencies and cutover

Trước khi bật endpoint: Owner duyệt canonical migration 001 + role fragment B3, backup/recovery assurance, clean migration history, PG17 integration/privilege tests, provision limited runtime role và trusted JWT authorization provider. Kiểm tra SQL candidate `transaction_type` whitelist và Prisma model. Audit mọi Flutter direct write và `confirm_outbound_order` RPC; lập kế hoạch chuyển một write path tại một thời điểm, xác nhận không double-subtract/double-ledger và giữ nguyên DTO. Reservation/order status chỉ triển khai sau khi workflow state và rollback contract được xác nhận. `002_reserved_limit_optional_candidate.sql` vẫn optional và chưa áp dụng.

## 10. Next recommended task and owner gates

TASK-DB-04D-B5: tạo môi trường/điều kiện PostgreSQL 17 hoặc một kế hoạch integration được Owner chấp thuận; kiểm adapter dưới role thật, RLS, concurrent requests, rollback, lock timeout, và approval authority; hoàn thiện JWT verifier và audit/cutover Flutter/RPC. Sau đó mới trình release 001 và task Cloud write riêng. Không tự triển khai migration trong B4.

## Git delivery

Implementation commit `14f4f5f` (`feat(backend): add unwired Prisma inventory transaction adapter`). Báo cáo commit riêng; hash/push status xác nhận trong phản hồi cuối. Chỉ stage/commit/push B4 code/tests/docs trên `feature/backend-nestjs-init`; năm SQL untracked và tài liệu untracked của Owner giữ nguyên.
