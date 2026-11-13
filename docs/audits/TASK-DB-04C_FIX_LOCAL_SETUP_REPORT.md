# TASK-DB-04C-FIX — Chuẩn bị kiểm thử migration trên PostgreSQL local

Ngày 13/11/2026. **Trạng thái: BLOCKED.** Không có database test hoặc migration nào được tạo/chạy. Không kết nối Supabase Cloud, không đọc credentials, không thay đổi `pg_hba.conf`, service, Flutter hay SQL chưa track của người dùng.

## 1. Local PostgreSQL status

Service `postgresql-x64-18` đang `Running`, data directory theo service là `C:\Program Files\PostgreSQL\18\data`. `pg_isready -h 127.0.0.1 -p 5432` trả về `accepting connections`. `psql.exe` có ở `C:\Program Files\PostgreSQL\18\bin\psql.exe`, phiên bản client 18.3; binary không nằm trong PATH. Docker Desktop và Supabase CLI không được tìm thấy trong lần kiểm tra DB-04C trước đó; không cài phần mềm hệ thống.

## 2. Authentication status

Đọc các rule hiệu lực theo thứ tự trong `C:\Program Files\PostgreSQL\18\data\pg_hba.conf`: `host all all 127.0.0.1/32 scram-sha-256` và `host all all ::1/128 scram-sha-256`. Đây là cấu hình trên đĩa của service đang chạy; chưa thể dùng SQL để xác nhận `hba_file` trong runtime vì chưa xác thực. Lệnh chỉ đọc `psql -X -w -h 127.0.0.1 -p 5432 -U postgres -d postgres ...` thất bại với `fe_sendauth: no password supplied`. Không thử mật khẩu mặc định hoặc bypass. `pg_isready` chỉ xác nhận server nhận kết nối, không xác nhận quyền truy cập.

**Project Owner cần thực hiện:** dùng mật khẩu **riêng của PostgreSQL local** trên máy của mình, nhập qua prompt tương tác của `psql.exe -X -W -h 127.0.0.1 -p 5432 -U postgres -d postgres`. Sau đăng nhập, chạy read-only `SELECT inet_server_addr(), current_database(), current_user, version();` và cung cấp **chỉ kết quả không nhạy cảm** hoặc tạo local test role qua quy trình quản trị riêng. Không gửi mật khẩu trong chat, shell command, Git, `.env` backend hay log. Nếu quên mật khẩu, Owner xử lý với quản trị viên local; task này không reset hoặc sửa auth.

## 3. Test database readiness

Tên dự kiến: `inventoryassistant_migration_test`, chỉ trên `127.0.0.1`; database `postgres` mặc định chỉ dùng để xác minh host/role. **Chưa tạo database**, vì chưa xác thực local và chưa có phê duyệt rõ ràng cho `CREATE DATABASE`. Sau khi Owner cung cấp local access an toàn và phê duyệt riêng, xác minh `inet_server_addr() = 127.0.0.1`, `current_database()`, `version()` và đích test trước mọi thao tác ghi. Dùng DSN local riêng, không dùng `DATABASE_URL` hoặc `DIRECT_URL` của `backend/.env`. Không chạy migration trong task này.

## 4. Missing baseline metadata

TASK-DB-03 xác nhận sáu bảng nghiệp vụ và `your_table`; TASK-DB-04A căn chỉnh Prisma mapping; DB-04B có design SQL. Chúng **không** chứa schema-only baseline đủ để phục dựng và kiểm chứng chính xác: DDL đầy đủ từng bảng, toàn bộ column type/nullability/default, PK/FK/unique/CHECK, index definition/order/partial predicates, RLS policies, grants, owner/default privileges, triggers, function bodies và dependencies, extension versions, reference tới `auth.users` và các object `auth` khác. Prisma schema không thể thay thế catalog PostgreSQL. Không có baseline đáng tin cậy nên không tái tạo sáu bảng bằng phỏng đoán.

**Phương án chuẩn bị:** khi Owner phê duyệt **riêng** thao tác export Cloud ở task khác, một người có quyền xuất schema-only `public` và các object `auth` cần thiết bằng công cụ PostgreSQL/Supabase chính thức, không gồm dữ liệu hàng hoặc credentials. Giữ file thô ngoài repo, rà soát function bodies/comments để loại secrets trước khi chia sẻ; giữ nguyên grants/RLS trong bản đã rà soát và kèm catalog metadata của owner, extensions, triggers và migration history. Đối chiếu checksum/cấu trúc với snapshot read-only được phép. Không chạy export hay kết nối Cloud trong task này.

## 5. Migration conflicts

Hai nguồn SQL cùng chủ đích tạo object; chỉ nên đưa **một bộ đã hợp nhất và được duyệt** vào Supabase migration history. Năm file `supabase/migrations/*.sql` hiện chưa track; bảng dưới là đề xuất, **không phải thao tác sửa file**.

| File nguồn chưa track | Object/trùng lặp với DB-04B | RLS | Constraints | Indexes | Nguy cơ / đề xuất |
| --- | --- | --- | --- | --- | --- |
| `20261113000001_create_stock_ledger.sql` | `stock_ledger` trùng `001_additive_design.sql` | Bật RLS, chờ policy 000005 | Thiếu `delta <> 0`, `balance >= 0`, FK `order_id`, trigger append-only; `created_by` dùng `SET NULL` thay vì `RESTRICT` | History index thiếu `id DESC`; thiếu order index | `IF NOT EXISTS` có thể che drift. Đề xuất thay nội dung bằng design 001 sau Owner review; giữ file người dùng nguyên trong task này. |
| `20261113000002_create_idempotency_keys.sql` | `idempotency_keys` trùng 001 | Bật RLS, chờ 000005 | PK `key` toàn cục, `user_id` nullable; hash không giới hạn; response/status/expiry ít ràng buộc hơn composite `(scope_id,key)` của 001 | `user_id` index + partial expiry khác 001 | API/Prisma contract xung đột. Chọn một model scope/status/TTL đã duyệt rồi tạo migration chuẩn duy nhất; không chạy cả hai. |
| `20261113000003_add_approved_by_to_warehouse_orders.sql` | `approved_by` trùng 001 | Không đổi | Nullable FK tương tự, nhưng `ADD COLUMN IF NOT EXISTS` không bảo đảm FK đúng nếu cột có trước | Partial index `WHERE approved_by IS NOT NULL` khác full index 001 | Quyết định index/FK tên cuối cùng, giữ một migration. |
| `20261113000004_add_inventory_constraints.sql` | Ba CHECK tồn kho trùng `002_inventory_checks_optional.sql` | Không đổi | CHECK validated ngay; 002 dùng `NOT VALID` và tách riêng | Không đổi unique index | Có thể fail trên dữ liệu cũ hoặc chặn Flutter/RPC writes. Chỉ xét sau preflight và Owner approval; không tự áp dụng 002. |
| `20261113000005_rls_stock_ledger_idempotency.sql` | Hai bảng mới trùng policy plan 001 | Cho `authenticated` SELECT toàn ledger và own keys; 001 revoke client grants, không tạo client policy | Không đổi | Không đổi | Có thể lộ audit và response metadata qua `public`; chọn deny-by-default của 001 trừ khi Owner phê duyệt use case đọc trực tiếp. |

Không sửa/xóa/stage năm file; không tạo Prisma Migrate history song song. Đề xuất Supabase migration history làm nguồn chính sau khi thống nhất một bộ file, kiểm tra checksum và loại các file trùng qua quy trình được phê duyệt.

## 6. Version compatibility

Cloud version 17.6 theo báo cáo DB-03 ngày 12/11/2026 (không xác minh lại Cloud); local service/client là PostgreSQL 18/18.3. PostgreSQL 17 docs có cú pháp `ADD ... NOT VALID` cho CHECK/FK; constraint vẫn áp dụng cho INSERT/UPDATE mới. CREATE TRIGGER, PL/pgSQL trigger function, row security/default-deny, composite DESC indexes và `gen_random_uuid()` đều được tài liệu PostgreSQL 17 mô tả. [ALTER TABLE 17](https://www.postgresql.org/docs/17/sql-altertable.html), [CREATE TRIGGER 17](https://www.postgresql.org/docs/17/sql-createtrigger.html), [RLS 17](https://www.postgresql.org/docs/17/ddl-rowsecurity.html), [CREATE INDEX 17](https://www.postgresql.org/docs/17/sql-createindex.html), [UUID functions 17](https://www.postgresql.org/docs/17/functions-uuid.html).

Đây là **đánh giá tương thích cú pháp, không phải chứng nhận migration chạy trên 17.6**. Parser PostgreSQL 18 đã đọc SQL DB-04B trong DB-04C; task này không chạy DDL. Cần kiểm thử cuối trên PostgreSQL 17/Supabase Local tương ứng, gồm auth roles, extensions, grants, trigger/RLS và index definitions; kết quả nếu chỉ có local 18 phải gắn nhãn **provisional**. Không tự cài PostgreSQL 17, Docker hay Supabase CLI.

## 7. Offline QA results

| Gate | Kết quả |
| --- | --- |
| `npm run prisma:validate` | PASS |
| `npm run prisma:generate` | PASS, Prisma Client 6.19.3 |
| `npm run build` | PASS |
| `npm run lint` | PASS |
| `npm run test` | PASS, 43/43; gồm static migration guards |
| `npm run test:e2e` | PASS, 5/5, mock Prisma |
| Local DB integration / migration 001, 002 | **NOT RUN / BLOCKED** |

Các QA commands trên không chạy database migration. Prisma validate/generate có log tải cấu hình `.env` theo CLI nhưng không mở kết nối DB và không in giá trị; không dùng các URL đó cho migration.

## 8. Git status

Trước task: `feature/backend-nestjs-init`, HEAD/upstream `ab67435b234e0abc4633627b66febd78e9d618be`, tracked diff rỗng; remote `origin` đúng repository. Hai mục chưa track có sẵn là tài liệu kế hoạch và năm SQL `supabase/migrations/`. Chỉ báo cáo này được commit bằng Conventional Commit và push lên `origin/feature/backend-nestjs-init`; hash commit báo cáo xem bằng `git log -1 --oneline` vì file không thể chứa hash của chính nó. Không commit secrets, không force push/merge/push main.

## 9. Blockers remaining

1. Thiếu xác thực/quyền quản trị PostgreSQL local qua `scram-sha-256`.
2. Chưa có schema-only/catalog baseline được duyệt và xác minh, gồm RLS/grants/auth dependencies.
3. Chưa có phê duyệt `CREATE DATABASE inventoryassistant_migration_test`.
4. Hai bộ migration trùng nhau chưa được Owner chọn/hợp nhất.
5. Local PostgreSQL 18 chưa đại diện đầy đủ cho Cloud PostgreSQL 17.6.

**Migration testing chưa PASS; không sẵn sàng review Cloud migration.**

## 10. Đề xuất task tiếp theo

Owner xác thực local bằng prompt `-W` và cung cấp kết quả probe không nhạy cảm; phê duyệt riêng tạo database test nếu muốn tiếp tục. Owner duyệt schema-only export ở task khác và phương án hợp nhất năm SQL chưa track. Sau đó dựng baseline local 17 tương thích, chạy preflight/001/kiểm tra FK/index/RLS/Prisma/concurrency trên data giả, đánh giá 002 riêng, thử backup/rollback; chỉ lúc đó cập nhật trạng thái review. Không kết nối hoặc triển khai Supabase Cloud trong TASK-DB-04C-FIX.
