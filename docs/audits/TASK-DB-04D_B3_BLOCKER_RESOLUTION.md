# TASK-DB-04D-B3 — Giải quyết blocker hợp đồng database (offline)

Ngày 13/11/2026. Branch `feature/backend-nestjs-init`, HEAD đầu task `882965c`, upstream cùng HEAD; tracked tree sạch. Hai untracked assets của Owner (`docs/KE_HOACH_KIEN_TRUC_TYPESCRIPT_BACKEND_SMART_WMS.md` và toàn bộ `supabase/migrations/` gồm năm SQL) được giữ nguyên, không stage. Đã đọc DB-04D-A/B/B2, AGENTS.md, Prisma schema, NestJS Prisma service/tests, Flutter DTO/datasources và SQL candidate. **Không kết nối Supabase Cloud, restore hoặc chạy migration.**

## BLOCKERS RESOLVED — ở mức thiết kế/mã offline

1. **Prisma mapping:** `backend/prisma/schema.prisma` đã bỏ relation creator/approver sai đích `profiles` (giữ scalar UUID vì `auth.users` Supabase-managed), bỏ default UUID phía Prisma của `Profile.id`, chỉnh InventoryItem FK `onDelete: Cascade`, thêm `StockLedger.inventoryItemId`/relation, bỏ creator relation không có FK và map ba index ledger đúng candidate. `IdempotencyKey` composite PK `(scopeId,key)` giữ nguyên. Không chạy query tới bảng/cột chưa tồn tại. `prisma validate/generate`, build và tests đạt; không có NestJS code hiện hữu dùng các relation đã bỏ. Prisma vẫn chứa vài index legacy không có standalone DB index; partial `warehouse_orders_approved_by_idx` là database-owned, không biểu diễn bằng Prisma `@@index` thường.
2. **Backend contract:** thêm `backend/src/inventory-contract/` gồm hàm hash JSON ổn định, state decision cho claim/conflict/replay/expired, guard int4/không âm/không over-reserve, guard ADMIN/MANAGER và transaction orchestration qua port. Sáu unit tests mới kiểm thứ tự claim → row lock → update → ledger → complete, replay không ghi kép và rollback mô phỏng khi ledger lỗi. Không có Prisma adapter/endpoint; chưa production-ready. Micro-tasks và acceptance criteria ở README.
3. **SQL staging:** 001 bổ sung fail-closed DB/PG17, auth FK và inventory UUID preconditions. `backend/sql/task_db_04d_b3/backend_role_access_candidate.sql` đề xuất role `wms_backend` LOGIN không mật khẩu trong SQL, không owner/BYPASSRLS/INHERIT; grants theo use case và RLS policies riêng. Fragment này phải được Owner review và hợp nhất **trong một canonical 001** sau phần tạo object, trước COMMIT, không chạy độc lập. B3 preflight/postcheck assertion scripts đọc catalog/aggregate, dùng transaction READ ONLY và raise exception khi drift; postcheck kiểm quyền hiệu lực client/backend, trigger, RLS và function grants. `002_reserved_limit_optional_candidate.sql` giữ nguyên và chưa áp dụng.

## Thiết kế quyền backend

`wms_backend` được đề xuất `USAGE public`; `SELECT (id,role)` trên profiles; `SELECT` trên products/locations/inventory_items/warehouse_orders/warehouse_order_items; `UPDATE` giới hạn cột số lượng/timestamp ở inventory, status/approved_by/timestamp ở orders; `SELECT/INSERT` ledger; `SELECT`, INSERT cột claim và UPDATE cột completion ở keys. Không có UPDATE/DELETE/TRUNCATE ledger hoặc DELETE keys (TTL cleanup cần thiết kế riêng). Các policy `TO wms_backend` cho SELECT/UPDATE/INSERT tương ứng; không mở policy cho Flutter. Vì schema chưa có tenant discriminator, backend policy `USING(true)` là cross-row và đòi hỏi NestJS kiểm tra principal/scope ở từng use case. **Chưa phải bảo đảm phân quyền theo tenant/user ở database.** Role được tạo LOGIN nhưng không có password nên chưa thể dùng cho runtime cho đến khi Operator provision credential an toàn và kiểm tra session. Runtime hiện cấu hình `postgres` qua Session Pooler trong `.env`, chưa đổi config hoặc in URL/password. [Supabase connection docs](https://supabase.com/docs/guides/database/connecting-to-postgres) nêu custom role dùng username dạng role + project suffix qua shared session pooler cổng 5432; operator phải lấy host/user thực từ Dashboard. Prisma `DATABASE_URL` runtime sau này dùng role hạn chế, admin migration credential tách riêng. Chưa kiểm thử session pooler.

## BLOCKERS REMAINING

| Blocker | Tình trạng và điều kiện giải quyết |
| --- | --- |
| Authorization cũ | Sáu bảng có policy `FOR ALL TO authenticated USING(true) WITH CHECK(true)` và grants rộng. `profiles.role` có thể bị client cập nhật theo audit hiện có, nên **không được tin** làm nguồn phê duyệt cho đến khi harden; `assertApproverRole` chỉ là guard thuần. Flutter hiện ghi status trực tiếp và gọi `confirm_outbound_order`, có thể bypass ledger. Audit/hardening và cutover cần Owner duyệt riêng. |
| ACID/idempotency thật | Port chưa có Prisma adapter. Phải dùng `INSERT ... ON CONFLICT DO NOTHING` + `SELECT FOR UPDATE` cùng transaction, khóa row inventory, so khớp item/product/location, update và insert ledger, completion đúng một row, lock timeout/deadlock policy. Test concurrent cùng key, hash conflict, retries/expiry, partial failure trên PostgreSQL thật. |
| SQL role/runtime | Fragment SQL chưa hợp nhất vào 001, chưa chạy PG17; role/password provisioning và `current_user`, grants, RLS/ACL/default privileges qua pooler chưa kiểm chứng. Role cross-row vẫn rộng; cần test quyền theo principal và chốt mô hình tenant. |
| Ledger integrity | Database chưa tự ép snapshot product/location bằng inventory item, `balance` bằng tồn kho committed, event uniqueness hoặc actor FK. Contract kiểm ở application; mọi write path khác còn có thể tạo lệch hoặc không ghi ledger. FK RESTRICT ảnh hưởng xóa record lịch sử cần Owner duyệt. |
| Legacy history/checkout | Theo Owner, Cloud chưa có `supabase_migrations.schema_migrations`. Giữ legacy six-table schema làm baseline hiện hữu; không tạo lại bằng 001. Trong task thực thi sau, tạo clean detached release checkout không chứa năm SQL untracked, đưa **một** canonical 001 đã duyệt vào `supabase/migrations/`, review file/version và `db push --dry-run` phải liệt kê đúng một file, không seed/roles/002. First approved push sẽ tạo history theo Supabase CLI; không `migration repair`/`db pull`/`db push` trong B3. Cần chiến lược tái tạo legacy schema cho môi trường mới riêng. [Supabase migration docs](https://supabase.com/docs/guides/deployment/database-migrations). |
| Backup/recovery | Supabase Free không có scheduled backups theo Owner. Manual CUSTOM backup vẫn chưa restore thử; không bao gồm Storage object bytes, roles/globals và external service state. Phải chốt recovery assurance/RPO/RTO trước Cloud write. [Supabase backup docs](https://supabase.com/docs/guides/platform/backups). |
| Optional CHECK/PG17 | `002` chưa audit mọi write path/RPC; thêm NOT VALID vẫn chặn write mới sai. SQL chỉ parse tĩnh bằng parser hiện có, chưa execute trên PG17, chưa đo lock của ALTER TABLE/CREATE INDEX trên orders. |

## Backup và TOC reconciliation

Chỉ kiểm tra metadata: file `D:\secure-review\backups\inventoryassistant_pre_migration_20261113.dump` có kích thước 438301 bytes; SHA-256 `D40E966DA05C61E8EAE93743BCDD36E068DC26E1D2B01983F37AE7DFFAA8BF27` **khớp hash quan sát ở B2** nhưng chưa có manifest độc lập từ Owner. `pg_restore 18.3 --list` exit 0, dump header báo source PG17.6; 726 dòng liệt kê = **711 object entries** (`^\d+;`) + 15 dòng comment/header. Con số 718 Owner báo trước không khớp một trong hai cách đếm này; cần đối chiếu phương pháp/manifest, **không có bằng chứng corruption từ chênh lệch count**. Không đọc table data, Auth/Vault rows hoặc raw backup; chưa restore, chưa chứng minh completeness/recovery.

## TESTED

| Gate | Kết quả | Giới hạn |
| --- | --- | --- |
| `npm run prisma:validate` / `npm run prisma:generate` | PASS / PASS | Offline; chỉ kiểm schema Prisma |
| `npm run lint` / `npm run build` | PASS / PASS | TypeScript offline |
| `npm run test` | PASS, 49/49 (43 cũ + 6 mới) | Fake transaction runner, không PG |
| `npm run test:e2e` | PASS, 5/5 | Mock-only |
| SQL static parse | PASS, 7/7 SQL staging files | Không tương đương PostgreSQL 17 execution |
| `git diff --check` | PASS trước stage; staged diff kiểm lại trước commit | Chỉ whitespace |

## NOT TESTED

Không có SQL integration/role/trigger test, concurrent database requests, actual Prisma transaction/row lock, Supabase Session Pooler login bằng role mới, Cloud schema drift check, Flutter smoke, `pg_restore` phục hồi, Storage recovery, PG17 runtime/lock rehearsal hoặc Cloud write. Không tuyên bố migration PASS.

## OWNER APPROVAL REQUIRED

1. Duyệt role `wms_backend`, phạm vi SELECT/UPDATE cross-row, secret provisioning và tách runtime/admin credentials; duyệt hardening `profiles.role`, sáu policy/grants cũ và RPC/Flutter write paths.
2. Duyệt transaction/idempotency/ledger retention contract, TTL cleanup, actor/approval authority và plan cắt chuyển các write paths.
3. Duyệt phương án backup/restore assurance phù hợp Supabase Free, giải thích TOC 718/711 và Storage recovery.
4. Duyệt canonical 001 hợp nhất fragment, clean release checkout, migration history baseline và PG17/security tests trước task thực thi Cloud riêng. Không tự chạy migration.

## Git delivery

Implementation commits: `e714a08` (Prisma + offline contract), `664bded` (SQL staging + assertions). Báo cáo commit riêng; hash tự thân và push status xác nhận trong phản hồi cuối. Chỉ commit/push code, SQL staging và báo cáo B3 trên `feature/backend-nestjs-init`; không stage user-owned untracked files, dump, backup hoặc secrets.
