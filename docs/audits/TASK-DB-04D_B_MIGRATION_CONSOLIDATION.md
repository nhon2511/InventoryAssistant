# TASK-DB-04D-B — Hợp nhất thiết kế Supabase migrations

Ngày 13/11/2026. **Chỉ thiết kế và kiểm tra offline. Không kết nối hoặc ghi Cloud, không restore, không chạy migration.**

## 1. Git baseline và bằng chứng

Branch `feature/backend-nestjs-init`, HEAD ban đầu `cbe3468`, upstream `origin/feature/backend-nestjs-init`; tracked tree sạch. `docs/KE_HOACH_KIEN_TRUC_TYPESCRIPT_BACKEND_SMART_WMS.md` và năm file `supabase/migrations/*.sql` là tài sản chưa track của người dùng, được giữ nguyên, không stage. Đã đọc AGENTS.md, tài liệu kiến trúc/quy chuẩn, báo cáo DB-03 đến DB-04D-A, Prisma schema, NestJS Prisma service/tests, Flutter `WarehouseOrderModel` và data-source liên quan. Flutter đọc/ghi tên `approved_by`, nullable.

Baseline Cloud dưới đây do Project Owner cung cấp từ preflight read-only, không được agent truy vấn lại: PostgreSQL 17.6; sáu bảng nghiệp vụ và `your_table`; chưa có `stock_ledger`, `idempotency_keys`, `approved_by`; hai CHECK không âm đã có, CHECK reserved <= on-hand chưa có; aggregate negative/over-reserved/duplicate NULL-lot đều 0; sáu policy RLS `FOR ALL TO authenticated USING(true) WITH CHECK(true)`; không có `supabase_migrations.schema_migrations`. Schema-only dump DB-04C-03B là bằng chứng snapshot cũ: hai FK đến `auth.users`, InventoryItem FK CASCADE, ACL/default grants rộng. Backup CUSTOM ngoài repo 438301 bytes, 718 TOC entries theo Owner; **chưa thử restore**, vì vậy vẫn chặn triển khai.

## 2. Conflict matrix

| File chưa track của Owner | Trùng với DB-04B | Sai khác quan trọng / nguy cơ | Quyết định candidate |
| --- | --- | --- | --- |
| `20261113000001_create_stock_ledger.sql` | `001_additive_design.sql`: bảng, index, RLS | Thiếu CHECK delta/balance/type, order FK, trigger append-only; actor FK profiles `SET NULL`; `IF NOT EXISTS` che drift; không có inventory item identity | Thay bằng staging 001: FK item/product/location/order, actor UUID bất biến, CHECK, trigger, index theo item. Không áp dụng hai bản. |
| `20261113000002_create_idempotency_keys.sql` | DB-04B 001: bảng/TTL | PK `key` toàn cục; `user_id` nullable, `expires_at` nullable, hash không kiểm dạng; status `failed`; khác Prisma composite PK | Staging 001 dùng `(scope_id,key)`, expiry bắt buộc và completion CHECK. |
| `20261113000003_add_approved_by_to_warehouse_orders.sql` | DB-04B 001: cột/FK/index | Cả hai dùng FK `profiles`; Cloud hiện dùng `auth.users` cho `created_by`; `IF NOT EXISTS` có thể che kiểu/FK sai | Staging 001 thêm nullable UUID, FK `auth.users ON DELETE SET NULL`, partial index. |
| `20261113000004_add_inventory_constraints.sql` | DB-04B 002: ba CHECK | Hai CHECK không âm đã có; thêm lại có thể trùng logic/tên. Dùng CHECK validated ngay có thể chặn write path hiện hữu | Staging 002 chỉ thêm `reserved <= on_hand NOT VALID`, cổng duyệt riêng. |
| `20261113000005_rls_stock_ledger_idempotency.sql` | DB-04B 001: RLS/security | Cho `authenticated` đọc cả ledger và own keys; không REVOKE default grants; không có bảo vệ append-only thực chất | Staging 001 bật RLS, revoke client/service_role grants, không có client policy. Backend privilege được quyết định riêng. |

Không phát hiện bằng chứng năm file trên đã được áp dụng; history vắng mặt theo Owner **không tự chứng minh** mọi SQL chưa từng chạy ngoài migration runner. Recheck catalog và history trước release. Không sửa/xóa/stage chúng trong task này.

## 3. Canonical database contracts

**StockLedger:** UUID PK, inventory item identity để phân biệt các slot NULL-lot, product/location/order FKs `RESTRICT`, delta khác 0, balance không âm, loại giao dịch whitelist; index theo item thời gian, product/location thời gian và order. `created_by` là actor UUID do backend xác minh từ JWT, không có FK: xóa `auth.users` sẽ không làm trigger rewrite ledger. Trade-off: DB không xác minh actor và các snapshot product/location có thể lệch item nếu backend ghi sai; use case phải khóa inventory row, xác minh item/product/location, UPDATE inventory và INSERT ledger trong **cùng transaction**, đối chiếu balance, rồi COMMIT. Trigger từ chối UPDATE/DELETE/TRUNCATE thông thường; table owner/superuser vẫn có quyền vượt qua, cần kiểm soát vận hành. FK `RESTRICT` có thể chặn xóa item/order sau khi có ledger, cần Owner duyệt retention.

**IdempotencyKey:** composite PK `(scope_id,key)`; scope lấy từ principal/tenant đã xác thực, không tin UUID client tự khai. Ràng buộc method/path/hash/status/status code/expiry. Backend phải chuẩn hóa method/path/body, băm request không chứa secrets; không lưu response có token/PII. Claim bằng INSERT unique trong transaction, duplicate same hash chờ hoàn tất hoặc trả in-progress, different hash = conflict; khóa row `FOR UPDATE`/transaction để không hai request cùng thực hiện side effect. Dùng một transaction cho claim, inventory/order changes, ledger và completed response; lỗi rollback tất cả. TTL cleanup phải bảo đảm không tái dùng key khi side effect còn cần dedup; không có cleanup tự động trong candidate. Thiết kế này **chưa có NestJS integration implementation**.

**Order approval:** `approved_by uuid NULL → auth.users(id) ON DELETE SET NULL`, index cho truy vấn theo approver. Dữ liệu cũ giữ NULL; không đổi status/workflow. Flutter DTO hiện dùng `approved_by`, không dùng `reviewed_by`.

**Inventory:** chỉ CHECK `quantity_reserved <= quantity_on_hand` ở migration optional; không đổi UNIQUE `(product_id,location_id,lot_number)` và NULL semantics. Aggregate 0 tại preflight không chứng minh tất cả write paths an toàn; đặc biệt RPC `confirm_outbound_order` phải audit concurrency trước khi áp dụng. `NOT VALID` vẫn kiểm tra các INSERT/UPDATE mới; VALIDATE sau là bước duyệt riêng.

## 4. SQL candidate files và một lịch sử chính

Nguồn lịch sử sau phê duyệt: **Supabase migrations duy nhất**; không tạo Prisma Migrate history. Các file staging tại `backend/sql/task_db_04d_b/`:

| File | Mục đích | Trạng thái |
| --- | --- | --- |
| `001_additive_core_candidate.sql` | Ledger, keys, approved_by, RLS/ACL, fail-closed prerequisite | Candidate, chưa thực thi |
| `002_reserved_limit_optional_candidate.sql` | Một CHECK mới `NOT VALID` | Candidate, cổng duyệt riêng |
| `preflight_read_only.sql` | Metadata, history presence, aggregate counts | Chưa chạy trong task này |
| `postcheck_read_only.sql` | Catalog/FK/index/trigger/RLS/ACL sau triển khai | Chưa chạy |
| `PRISMA_ALIGNMENT_REVIEW.md` | Diff đề xuất, không sửa Prisma | Để Owner review |
| `ROLLBACK_AND_FORWARD_FIX.md` | Xử lý lỗi theo điểm COMMIT | Kế hoạch |

Candidate không dùng `IF NOT EXISTS`, không tạo lại sáu bảng, không DROP/TRUNCATE, không đổi `your_table`/Auth/RLS hiện hữu. Staging không nằm trong đường auto-deploy. Sau Owner duyệt, xác minh version history và checksum, bảo vệ/giải quyết năm file chưa track, rồi tạo **một** version Supabase mới cho 001 và một version tùy chọn cho 002. Không đặt tên version cuối cùng khi history chưa được baseline; không sửa migration đã thực thi. Có thể cần khởi tạo/baseline Supabase history theo quy trình riêng vì bảng history đang vắng mặt; không chạy `migration repair` hoặc `db push` trong task này.

## 5. Prisma compatibility

`Profile.id @default(uuid())` không phản ánh default DB; `WarehouseOrder.creator` và `.approver` trỏ Profile trong Prisma trong khi creator Cloud trỏ `auth.users` và candidate approver cũng vậy; InventoryItem `onDelete: Restrict` khác Cloud CASCADE. StockLedger cần `inventoryItemId`; creator relation Profile phải bỏ theo actor snapshot. Nhiều `@@index` hiện có không có standalone DB index; partial approved_by index không thể biểu diễn bằng Prisma `@@index` thường. Xem `PRISMA_ALIGNMENT_REVIEW.md`. Không sửa `schema.prisma`, không dùng model/cột chưa tồn tại cho query thật, không chạy Prisma Migrate/db push. Existing NestJS hiện chỉ có Prisma service và skeleton, chưa có transactional write path.

## 6. Security/RLS

Hai bảng mới bật RLS, không tạo policy client, REVOKE từ PUBLIC/anon/authenticated/service_role để tránh default grants của Supabase public. Backend cần thiết kế role/privilege riêng hoặc đường server-side đã rà soát, không đặt `service_role` ở Flutter. Quyền owner/superuser và `BYPASSRLS` cần kiểm soát; RLS/trigger không thay thế privilege review. Candidate không sửa sáu policy hiện hữu `USING(true)` dù đây là rủi ro cao, cần task hardening riêng; `confirm_outbound_order` hiện có GRANT EXECUTE rộng theo dump cũ, cần audit riêng trước release. Không cache response chứa credential/PII.

## 7. Offline checks

| Kiểm tra | Kết quả | Giới hạn |
| --- | --- | --- |
| `pglast.parse_sql` trên 4 SQL staging files | PASS | Cú pháp tĩnh; không kiểm tra catalog/privilege/runtime |
| Scan DDL staging | PASS: 2 CREATE TABLE mới, 0 CREATE bảng cũ, 0 client policy, 1 optional CHECK, 0 CHECK không âm trùng | Regex/static; `IF NOT EXISTS` xuất hiện trong comment cấm dùng, không có trong DDL |
| `npm run prisma:validate` / `npm run prisma:generate` | PASS / PASS | Không kết nối DB |
| `npm run lint` / `npm run build` | PASS / PASS | Backend offline |
| `npm run test` | PASS, 43/43 | Unit/mocks, không thực thi migration |
| `npm run test:e2e` | PASS, 5/5 | Mock-only; output có stack trace dự kiến nhưng exit code 0 |
| Backup file metadata | Tồn tại, kích thước 438301 bytes | TOC 718 entries theo Owner; agent không đọc dữ liệu/TOC; restore chưa thử |
| `git diff --check` | PASS | Kiểm tra staged diff thêm trước commit |

**Chưa có SQL integration test, Cloud migration, local restore hoặc rollback rehearsal.** PostgreSQL 18 local nếu dùng sau này chỉ provisional so với Cloud PostgreSQL 17.6.

## 8. Remaining blockers

1. Backup mới chỉ đọc được archive, chưa chứng minh restore; phải test restore ở môi trường cô lập hoặc có recovery assurance được Owner duyệt.
2. Chưa có lịch sử Supabase migrations; cần quy trình baseline/history và đối chiếu object thực tế ngay trước release.
3. Chưa có backend role/grants tối thiểu, NestJS ACID/idempotency implementation, concurrency tests, Flutter smoke test.
4. Chưa audit tất cả write paths cho CHECK optional hoặc hiện trạng RLS/RPC rộng.
5. Chưa chạy candidate trên PostgreSQL 17 tương đương Cloud, chưa đánh giá lock/timeouts dưới dữ liệu thật.
6. Cần quyết định retention FK `RESTRICT`, actor UUID không FK, quyền đọc lịch sử/keys và cleanup TTL.

## 9. Đề xuất trình tự Cloud deployment (task khác, chưa được phép)

Owner duyệt contract/role/backup → chạy lại preflight read-only đúng target/TLS và xác nhận no drift, data aggregate 0/history → thử restore và migration trên môi trường cô lập PG17 → tạo version Supabase duy nhất từ staging sau khi giải quyết năm file chưa track → kiểm tra privilege/backend transaction → Operator được phê duyệt áp dụng 001 một lần → postcheck, NestJS/Flutter smoke → chỉ cân nhắc 002 sau audit write paths và duyệt riêng → VALIDATE CHECK riêng. Dừng ở bất kỳ target/history/schema/permission drift hoặc backup không tin cậy.

## 10. Owner approval checklist

- Chấp nhận FK/retention và actor snapshot, scoped idempotency/TTL/response redaction.
- Chấp nhận không có Flutter direct access với hai bảng; duyệt backend role/grants và hardening RLS/RPC riêng.
- Xác nhận backup có thể restore, PG17 rehearsal, history baseline và chiến lược xử lý năm file chưa track.
- Duyệt candidate 001, rồi 002 riêng sau audit write paths; phê duyệt TASK-DB-04D-C riêng trước **bất kỳ** Cloud write nào.

## Git delivery

Implementation commit: `49b5d32` (`feat(db): stage consolidated Supabase migration candidates`). Báo cáo được commit riêng theo Conventional Commits (hash của chính commit báo cáo không thể tự ghi trước commit). Chỉ stage file trong thư mục staging và báo cáo này; không stage user-owned untracked files, backup/dump/secrets. Push mục tiêu là `origin/feature/backend-nestjs-init`, không force push/merge/main. Kết quả push thực tế được xác nhận trong phản hồi cuối task.
