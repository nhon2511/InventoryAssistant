# TASK-DB-04C — Local PostgreSQL migration validation

Ngày 13/11/2026. **Kết luận: BLOCKED — chưa đủ điều kiện READY FOR CLOUD MIGRATION REVIEW.** Không kết nối Supabase Cloud, không chạy SQL ghi, không tạo database, không sửa Flutter hoặc năm migration chưa track của người dùng.

## 1. Executive Summary

PostgreSQL 18 local đang chạy trên `127.0.0.1:5432`, nhưng `psql -w` không xác thực được (`fe_sendauth: no password supplied`). Không đọc credentials từ `.env` hay nơi khác. Các báo cáo DB-03/04A/04B ghi cấu trúc tổng quát nhưng không có bản schema-only/catalog đầy đủ để dựng chính xác sáu bảng, RLS và grants. Vì vậy không được suy đoán baseline hoặc chạy migration 001. Kiểm tra Prisma, build, lint, unit, mock E2E và SQL parser đều PASS; chúng không thay thế kiểm thử database.

## 2. Git Baseline

Branch `feature/backend-nestjs-init`, HEAD và upstream đều `535040383d8e2dc8bf286a4e7a97b7099119ac80` lúc bắt đầu; tracked diff rỗng. Remote `origin` là repository đã nêu trong task. Working tree có hai mục chưa track từ trước: `docs/KE_HOACH_KIEN_TRUC_TYPESCRIPT_BACKEND_SMART_WMS.md` và năm file `supabase/migrations/*.sql`. Chúng được đọc để đối chiếu nhưng không sửa, xóa, stage hay commit. `git ls-files` xác nhận SQL ở `backend/sql/task_db_04b/` đã track, còn năm file Supabase chưa track. Không có Prisma migration history được track.

## 3. Local Environment Status

| Thành phần | Kết quả |
| --- | --- |
| PostgreSQL server | Service `postgresql-x64-18` RUNNING; `pg_isready -h 127.0.0.1 -p 5432` nhận kết nối |
| PostgreSQL client | Có tại `C:\Program Files\PostgreSQL\18\bin\psql.exe`, chưa có trong PATH |
| Local authentication | BLOCKED: kết nối read-only `-X -w -h 127.0.0.1 -p 5432 -U postgres -d postgres` báo thiếu password; không có truy vấn nào được thực thi |
| Docker Desktop / Supabase CLI | Không tìm thấy CLI; không cài thêm phần mềm hệ thống |
| Prisma CLI | Có `backend/node_modules/.bin/prisma.cmd`; chạy qua npm scripts |
| Baseline version | Cloud theo DB-03 là PostgreSQL 17.6; local là 18, cần xác nhận khác biệt version trước khi coi kết quả local là đại diện |

Trước mọi thao tác ghi ở task tiếp theo: dùng credential **riêng cho local**, kết nối chỉ tới `127.0.0.1`, chạy read-only probe xác nhận `inet_server_addr()`, `current_database()`, `current_user`, `version()`, và database đích là tên test mới riêng; tuyệt đối không lấy `DATABASE_URL`/`DIRECT_URL` từ `backend/.env` cho migration. Tạo test database chỉ sau khi xác minh host và quyền. Không đổi `pg_hba.conf` hoặc mật khẩu máy của người dùng trong task này.

## 4. Existing Migration Conflict Analysis

| File Supabase chưa track | Thiết kế DB-04B tương ứng | Xung đột / rủi ro |
| --- | --- | --- |
| `20261113000001_create_stock_ledger.sql` | `001_additive_design.sql` ledger | Cùng tạo bảng. Bản chưa track thiếu CHECK `delta <> 0`, `balance >= 0`, FK `order_id` và trigger append-only; `created_by ON DELETE SET NULL` xóa dấu vết tác giả. Index lịch sử không có `id` làm tie-breaker. |
| `20261113000002_create_idempotency_keys.sql` | `001_additive_design.sql` idempotency | Cùng tạo bảng nhưng contract không tương thích: PK chỉ `key` thay vì `(scope_id,key)`, `user_id` nullable, hash text không giới hạn, thiếu completion invariant, TTL nullable, `failed` status khác thiết kế. Áp dụng cả hai sẽ lỗi hoặc che drift bởi `IF NOT EXISTS`. |
| `20261113000003_add_approved_by_to_warehouse_orders.sql` | `001_additive_design.sql` `approved_by` | Cùng thêm cột; `IF NOT EXISTS` có thể bỏ qua cột đã tồn tại mà không đảm bảo FK đúng. Index partial khác index thường của bản DB-04B. Flutter dùng `approved_by`. |
| `20261113000004_add_inventory_constraints.sql` | `002_inventory_checks_optional.sql` | Cùng ba quy tắc với tên khác; bản chưa track áp dụng CHECK validated ngay, có thể fail nếu dữ liệu cũ vi phạm. DB-04B tách riêng và dùng `NOT VALID` nhưng vẫn chặn writes mới vi phạm. Không áp dụng 002 trong task này. |
| `20261113000005_rls_stock_ledger_idempotency.sql` | `001_additive_design.sql` deny-by-default | Bản chưa track cho `authenticated` đọc toàn bộ ledger và đọc key của mình; DB-04B không cấp quyền client cho hai bảng. Policy trên `public` có thể lộ audit/response metadata nếu grants phù hợp. Cần Owner quyết định contract trước khi hợp nhất. |

Khuyến nghị một nguồn lịch sử là **Supabase migrations** sau khi Owner chọn một bộ SQL chuẩn và loại xung đột bằng thay đổi được phê duyệt. Không tạo history song song bằng Prisma Migrate; không đưa bản thiết kế vào auto-deploy. Không tự ghi đè năm file của người dùng.

## 5. Database Baseline Reconstruction

DB-03 xác nhận sáu bảng nghiệp vụ (`profiles`, `products`, `locations`, `inventory_items`, `warehouse_orders`, `warehouse_order_items`) và `your_table`. DB-04A/04B mô tả Prisma mapping; `schema.prisma` đã được kiểm tra về các model/quan hệ. Tuy nhiên không có DDL/catalog snapshot đáng tin cậy chứa đầy đủ defaults, constraint definitions, tất cả indexes, RLS policies, grants, ownership và auth schema dependencies. `schema.prisma` không thể được coi là bản sao PostgreSQL. **BLOCKED**: không dựng baseline từ suy đoán, không sao chép dữ liệu thật hoặc Cloud credentials. `your_table` giữ nguyên.

Cần schema-only export hoặc catalog report đã rà soát từ nguồn được phép, không có business data/secrets; đối chiếu cột/type/nullability/default/PK/FK/unique/index/RLS/grants với metadata thực tế trước local bootstrap. Cần mô phỏng các role Supabase (`anon`, `authenticated`) để kiểm thử quyền; vanilla PostgreSQL 18 không tự có chúng.

## 6. Migration Execution Results

`preflight_read_only.sql`: **BLOCKED**, không có database test xác thực. `001_additive_design.sql`: **BLOCKED**, chưa apply. Hai bảng, `approved_by`, FK/index/CHECK/RLS/grants: **CHƯA KIỂM CHỨNG trên DB**. `002_inventory_checks_optional.sql`: **không áp dụng**, đúng theo yêu cầu đánh giá riêng. SQL parser PASS 3/3 file chỉ xác nhận cú pháp PostgreSQL; không xác nhận DDL, trigger body, privileges hay khả năng thực thi trên Supabase 17.6.

## 7. RLS & Permissions Tests

Database-level tests **BLOCKED**. Khi có local baseline, kiểm tra `relrowsecurity`, `pg_policies`, `has_table_privilege` và quyền function; thử `SET ROLE anon`/`authenticated` trong local: SELECT/INSERT/UPDATE/DELETE trên hai bảng mới phải bị từ chối, còn backend role chỉ được quyền đã duyệt. Test owner/bypass RLS riêng và xác minh schema `public` không phơi dữ liệu qua API. Không dùng `service_role` ở Flutter. Bản DB-04B hiện chưa cấp quyền cho role backend chuyên dụng; đây là thiết kế chờ phê duyệt, không phải runtime end-to-end đã đạt.

## 8. Stock Ledger Tests

Database-level tests **BLOCKED**. Dùng data giả để kiểm tra INSERT hợp lệ, `delta = 0`/`balance < 0` bị CHECK từ chối, FK sai bị từ chối, UPDATE/DELETE bị trigger từ chối, FK `order_id`/`created_by` giữ lịch sử và index tồn tại. Cần xác nhận balance là tổng theo product/location, trong khi inventory có lot. Không có use case NestJS tự động ghi ledger hiện tại; không tuyên bố ledger và inventory luôn đồng bộ.

## 9. Idempotency & Concurrency Tests

Database-level tests **BLOCKED**. Kịch bản hai phiên trên DB local: cùng `(scope_id,key)` và cùng fingerprint phải có đúng một claim; cùng key khác hash trả conflict ở backend; concurrent INSERT phải chờ unique conflict; rollback trước commit giải phóng claim; retry sau completed trả kết quả an toàn; completed response có thể NULL. Test expiration/cleanup và không lộ response nhạy cảm. Database chỉ đảm bảo uniqueness/transaction; logic so hash, HTTP 409, replay và TTL worker chưa triển khai NestJS nên **backend business tests BLOCKED**.

Concurrent outbound stock: dùng hai transaction trên cùng inventory row, khóa/cập nhật có điều kiện, kiểm tra không âm và ledger + inventory cùng COMMIT/ROLLBACK. Migration 001 không thêm CHECK cho inventory; 002 chưa áp dụng. Không có NestJS stock transaction use case, vì vậy **không có end-to-end stock transaction PASS**.

## 10. Flutter Compatibility

Đọc sáu DTO hiện tại: `ProfileModel` (`full_name`, `role`, `phone_number`), `ProductModel` (`sku`, `barcode`, `unit`, `min_safety_stock`), `LocationModel` (`*_code`, `location_barcode`, `max_capacity_kg`), `InventoryItemModel` (`lot_number`, `expiry_date`, quantities), `WarehouseOrderModel` (`approved_by`), `WarehouseOrderItemModel` (`expiry_date`, quantities). SQL 001 chỉ thêm bảng và nullable `approved_by`, không đổi/xóa cột DTO; **static compatibility PASS**. Runtime Flutter + local Supabase/PostgREST compatibility **BLOCKED** vì chưa có baseline local/API. Không sửa Flutter.

## 11. QA Results

| Gate | Kết quả |
| --- | --- |
| `npm run prisma:validate` | PASS |
| `npm run prisma:generate` | PASS; Prisma Client 6.19.3 |
| `npm run build` | PASS |
| `npm run lint` | PASS |
| `npm run test` | PASS, 43/43; test SQL design là static guards |
| `npm run test:e2e` | PASS, 5/5; Prisma mock |
| `pglast.parse_sql` | PASS, 3/3 file SQL DB-04B; parser-only |
| Local PostgreSQL integration / Prisma query against migrated DB | BLOCKED |

## 12. Commit Hashes & Push Status

DB-04B trước đó: `8386dd7` (design), `5350403` (report). Báo cáo DB-04C là commit tài liệu riêng trong cùng feature branch; hash xem bằng `git log -1 --oneline` sau commit vì file không thể chứa hash của chính nó. **Push status cuối task: commit báo cáo được push tới `origin/feature/backend-nestjs-init`.** Không push main, force push, merge hay commit secrets.

## 13. Unresolved Risks

Thiếu authentication local và metadata baseline chính xác; PostgreSQL local 18 khác Cloud 17.6; hai bộ SQL trùng nhau, contract RLS/idempotency bất đồng; chưa kiểm chứng trigger/FK/index/grants; backend chưa có transaction/idempotency flow; CHECK tồn kho optional chưa được audit trên dữ liệu. Vì các điều kiện quan trọng này chưa đạt, trạng thái là **BLOCKED**.

## 14. Recommendation for TASK-DB-04D

Project Owner cung cấp/thiết lập credential local test riêng qua cơ chế an toàn và bản schema-only/catalog snapshot đã rà soát, không chứa data/secrets. Sau đó tạo database test mới trên loopback, dựng baseline, chạy preflight và 001, thử các ca quyền, ledger, concurrency, Prisma, rollback/restore. Xác nhận chiến lược hợp nhất năm file Supabase chưa track, backup và rollback. Chỉ sau khi toàn bộ gate đạt mới đề xuất **READY FOR CLOUD MIGRATION REVIEW** trong task riêng; không tự chạy Cloud migration.
