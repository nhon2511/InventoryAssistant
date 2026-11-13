# TASK-DB-04C-02 — Chuẩn bị schema-only baseline

Ngày 13/11/2026. **Trạng thái: PLAN READY; chờ Project Owner phê duyệt riêng Cloud schema-only export.** Không kết nối Supabase Cloud, không export, restore hoặc chạy migrations trong task này.

## 1. Local database verification

Project Owner xác nhận đã tạo `inventoryassistant_migration_test`, đăng nhập thành công bằng `postgres` và chạy `SELECT inet_server_addr(), current_database(), current_user, version()` trên `127.0.0.1:5432` (PostgreSQL 18.3). Đây là **xác nhận từ Owner**, không phải kết quả SQL độc lập của agent. Agent kiểm tra service `postgresql-x64-18` đang `Running`, `pg_isready -h 127.0.0.1 -p 5432` nhận kết nối, `psql`, `pg_dump`, `pg_restore` đều là phiên bản 18.3. Truy vấn `psql -X -w` của agent tới **đúng database test** báo `fe_sendauth: no password supplied`; không có query được thực thi. Không yêu cầu Owner gửi password qua chat; nếu một task sau cần chạy SQL, Owner nhập mật khẩu qua prompt terminal của họ. Không tạo lại database, sửa auth hoặc ghi DB.

Git đầu task: branch `feature/backend-nestjs-init`, HEAD/upstream `061196a3cc9e86fe183e9b2cf4490d6f4ab3108e`, tracked diff rỗng. `docs/KE_HOACH_KIEN_TRUC_TYPESCRIPT_BACKEND_SMART_WMS.md` và năm file `supabase/migrations/*.sql` chưa track vẫn thuộc thay đổi của người dùng; không sửa/stage/commit.

## 2. Schema export strategy

TASK-DB-03 ghi nhận sáu bảng nghiệp vụ `public.profiles`, `products`, `locations`, `inventory_items`, `warehouse_orders`, `warehouse_order_items`, thêm `your_table`; Cloud version khi kiểm tra là 17.6. TASK-DB-04A căn chỉnh Prisma mapping; DB-04B/04C thiết kế migration và chỉ ra thiếu baseline. Prisma schema **không** thay thế bản DDL thực tế. Bản xuất cần chứa definitions của toàn bộ `public` liên quan và phần `auth` cần cho FK `profiles.id → auth.users.id`, function/policy dùng `auth.uid()` và các dependencies khác được phát hiện, không chứa rows.

Lấy **schema-only plain SQL** vào thư mục bảo mật *ngoài repository* để có thể rà soát. Chọn `public` và `auth` làm tập ban đầu; `pg_dump --schema` không tự kéo các dependency ở schema khác, vì vậy phải kiểm tra references/extensions và bổ sung schema phụ thuộc đã xác minh trước khi coi dump là đủ. Không tự giả định auth schema đã đầy đủ cho Supabase local runtime. Giữ ACL/GRANT trong dump để đối chiếu quyền; `--no-owner` làm bản restore local dễ kiểm soát hơn nhưng owner gốc phải được ghi riêng bằng catalog metadata. Không dùng `--no-acl` hoặc `--clean`. Không đưa raw dump chưa rà soát vào Git. [PostgreSQL 18 pg_dump](https://www.postgresql.org/docs/18/app-pgdump.html) xác nhận `--schema-only` không chứa table data, `-n` không tự thu dependency ngoài schema đã chọn, và client 18 có thể dump server 17.

### Lệnh export đề xuất — **CHƯA THỰC THI**

Owner thực hiện trong phiên terminal riêng, sau phê duyệt Cloud export; thay placeholders bằng thông số đã xác minh từ Supabase Development. Không đặt URI/password trên command line, không dùng `backend/.env`, không bật shell tracing, không gửi output thô vào chat. `-W` yêu cầu nhập password tương tác.

```powershell
& 'C:\Program Files\PostgreSQL\18\bin\pg_dump.exe' `
  --host 'APPROVED_DEVELOPMENT_DB_HOST' --port 'APPROVED_PORT' `
  --username 'APPROVED_EXPORT_USER' --dbname 'postgres' -W `
  --schema-only --no-owner --schema 'public' --schema 'auth' `
  --file 'D:\secure-review\inventoryassistant_schema_only.sql'
```

`D:\secure-review` chỉ là ví dụ cho thư mục hạn chế quyền truy cập nằm ngoài repo; Owner chọn đường dẫn thật trước khi chạy. `pg_dump` không lấy rows của `auth.users` trong chế độ này. Nếu role export không đủ quyền đọc metadata, dừng; không mở rộng quyền hoặc dùng credentials khác tùy tiện. Cần kiểm tra tên host/port thực tế và trạng thái SSL theo cơ chế được Owner duyệt trước lệnh. Không chạy lệnh trên trong task này.

### Metadata kèm theo cần rà soát

Dump cần được đối chiếu với catalog report read-only đã được phê duyệt: tên/kiểu/nullability/default của cột; PK, FK (đặc biệt `auth.users`), UNIQUE/CHECK; index definitions/predicates; RLS enable/force + policies; grants/default privileges và owner; trigger + function definitions/dependencies; extension name/version/schema; các schema mà function/policy/FK tham chiếu; Supabase migration history **metadata**, không export rows nghiệp vụ. Không dùng `pg_dumpall --globals-only` vì có thể mang thông tin role nhạy cảm; thu riêng danh sách role names/attributes cần mô phỏng, không password hashes.

## 3. Security review before sharing/restore

`--schema-only` loại table rows nhưng có thể giữ function bodies, comments, view definitions, policies và GRANT statements. Người có quyền phải rà soát chúng để loại hard-coded tokens/secrets, PII hoặc endpoint nhạy cảm. Không chia sẻ raw dump nếu chưa rà soát; lưu bản thô ngoài Git, giới hạn quyền file, chỉ chia sẻ bản đã kiểm tra theo kênh được Owner duyệt. Không sao chép Cloud credentials sang local. Không export `auth.users` data. Nếu cần chỉnh SQL để loại secrets hoặc dependency Supabase-managed không chạy trên vanilla PostgreSQL, lưu bản biến đổi riêng, ghi diff và lý do; không coi bản đã biến đổi là bản sao chính xác của Cloud.

## 4. Local restore strategy — **CHƯA THỰC THI**

Sau khi Owner phê duyệt export, có dump đã rà soát và xác thực local tương tác, kiểm tra file không có `COPY ... FROM stdin`, `INSERT INTO`, `\copy` hoặc dữ liệu người dùng; kiểm tra thêm nội dung function/comment bằng mắt, vì tìm chuỗi không chứng minh an toàn. So sánh version/extension và dependency closure. `inventoryassistant_migration_test` phải được xác nhận bằng read-only probe ngay trước restore; khảo sát nó có rỗng và không có dữ liệu người khác, nếu không thì dừng. Không `DROP DATABASE`, `--clean`, `--create` hoặc restore vào `postgres` mặc định.

Trước restore, kiểm tra các role được ACL tham chiếu (`anon`, `authenticated`, v.v.) và extensions. Vanilla PostgreSQL có thể thiếu Supabase-managed roles/functions; việc tạo role là thay đổi **cluster-wide**, ngoài phạm vi phê duyệt hiện tại. Dừng và đề xuất Supabase Local hoặc phê duyệt riêng nếu cần mô phỏng roles. Đọc và duyệt SQL một lần nữa vì restore có thể thực thi code trong function/trigger của source dump. [PostgreSQL 18 pg_restore](https://www.postgresql.org/docs/18/app-pgrestore.html) cảnh báo restore có thể thực thi code từ source, kể cả partial dump. Sau restore được phép trong task khác: đối chiếu catalog cho FK/index/RLS/triggers/grants với Cloud metadata, rồi kiểm tra Prisma mappings bằng query read-only. **Không chạy migration 001/002 ngay sau restore**; cần baseline sign-off riêng trước preflight/migration test.

## 5. PostgreSQL version compatibility

Local 18.3, Cloud 17.6 theo báo cáo DB-03, chưa xác minh lại Cloud. `pg_dump` 18 có thể xuất server 17; SQL dump được thiết kế để nạp lên phiên bản server **mới hơn client dump**, phù hợp chiều 17 → 18 nhưng không chứng minh chiều 18 → 17. [PostgreSQL 18 pg_dump](https://www.postgresql.org/docs/18/app-pgdump.html). Những gì chạy trên local 18 chỉ **provisional**. Kiểm thử cuối nên dùng PostgreSQL 17/Supabase Local tương thích và rà soát extension/role/RLS của môi trường Supabase thực tế; không tự cài phần mềm trong task này.

## 6. Migration conflicts và nguồn lịch sử

Năm SQL chưa track ở `supabase/migrations/` trùng object với `backend/sql/task_db_04b/001_additive_design.sql` và optional `002_inventory_checks_optional.sql`. 000001 thiếu ledger append-only trigger/CHECK/FK; 000002 dùng PK `key` thay vì `(scope_id,key)`; 000003 thêm cùng `approved_by`; 000004 áp CHECK validated ngay; 000005 cấp authenticated SELECT rộng hơn deny-by-default design. Chi tiết so sánh ở [TASK-DB-04C-FIX](TASK-DB-04C_FIX_LOCAL_SETUP_REPORT.md). Đề xuất chỉ dùng **Supabase migration history** sau khi Owner duyệt một bộ hợp nhất; không áp dụng đồng thời hai bộ, không tạo Prisma Migrate history. Không sửa năm file chưa track trong task này.

## 7. Blockers và next approval gate

- Chưa có Cloud schema-only export được Owner phê duyệt; task này không kết nối Cloud.
- Agent chưa tự xác thực SQL local vì không có password; chỉ có xác nhận của Owner và `pg_isready`.
- Chưa kiểm tra dependency closure, roles/extensions, ACL/RLS hoặc nội dung dump; local restore và Prisma query chưa thực hiện.
- Chưa thống nhất năm SQL chưa track với DB-04B design; version local 18 chưa đủ cho final PG17 gate.

**Gate kế tiếp:** Project Owner phê duyệt riêng phạm vi và người thực hiện schema-only export từ Supabase Development, phương thức bảo quản/rà soát dump, và việc chia sẻ metadata không nhạy cảm. Sau đó lập task restore local với xác thực host/database ngay trước write. TASK-DB-04C-02 dừng tại kế hoạch này; không tuyên bố baseline hay migration test PASS.
