# TASK-DB-04C-03 — Controlled schema-only export

Ngày 13/11/2026. **Kết quả: BLOCKED trước khi kết nối Cloud.** Project Owner đã cho phép export read-only, nhưng agent không có cặp target/credential được xác minh an toàn cho đúng Supabase Development. Không có phiên Supabase Dashboard đang mở để đối chiếu. Không chạy `pg_dump`, không tạo raw dump, không đọc `backend/.env`, không kết nối Cloud hoặc local DB, không restore/migration.

## 1. Target verification

Branch `feature/backend-nestjs-init`, HEAD/upstream đầu task `186165d7be26eea4103b80b2cb6e10c06e3e5bd5`; tracked diff rỗng. Năm file SQL chưa track ở `supabase/migrations/` cùng tài liệu kế hoạch chưa track của người dùng được giữ nguyên. Báo cáo DB-03 xác nhận trong **lần kiểm tra trước** project reference giữa Flutter và backend khớp, dùng shared session pooler IPv4 cổng 5432, và PostgreSQL 17.6. Nó không cung cấp bằng chứng target hiện tại để agent xác minh độc lập. Chưa có host/user lấy từ Dashboard, chưa đối chiếu project reference ID, chưa kiểm tra tài khoản export có quyền, và chưa chứng minh TLS cho một kết nối thực tế. **Target verification: BLOCKED.** Không ghi project reference ID vào báo cáo.

`pg_dump.exe` 18.3 có tại `C:\Program Files\PostgreSQL\18\bin\pg_dump.exe`. Không có `PGHOST`, `PGPORT`, `PGUSER`, `PGDATABASE`, `PGSERVICE`, `PGPASSWORD` hoặc `PGPASSFILE` trong môi trường shell được kiểm tra (chỉ kiểm tra tên biến, không đọc giá trị). Không dùng `backend/.env` làm nguồn credentials. Không có Supabase connector chuyên dụng trong tools và không thấy phiên Dashboard mở trong browser inventory. Vì agent không thể nhập mật khẩu tương tác của Owner một cách an toàn, Owner cần chạy lệnh đã rà soát dưới đây trong terminal của họ sau khi tự đối chiếu target.

## 2. Export method — đề xuất, **chưa thực thi**

Trong Supabase Dashboard của **Development** project, Owner tự đối chiếu reference ID của project với cấu hình Flutter ở máy mình mà không chia sẻ ID công khai. Lấy hostname/port/username **nguyên văn** từ màn hình Connect. [Supabase hướng dẫn](https://supabase.com/docs/guides/database/connecting-to-postgres) ưu tiên direct connection cho `pg_dump`; direct mặc định cần IPv6, còn session pooler cổng 5432 là phương án cho mạng IPv4. Không dùng transaction pooler 6543. Không suy ra pooler host từ region hoặc đoán username. Nếu direct không thể truy cập, Owner xác minh session mode là đúng project trước khi dùng. Không dùng connection URI có password trên command line.

Owner chạy trong terminal riêng; ví dụ PowerShell dưới đây **không được agent thực thi**. Thư mục đích phải nằm ngoài repository, có quyền truy cập hạn chế và được Owner tạo/chọn trước. `-W` yêu cầu nhập password tương tác. `PGSSLROOTCERT=system` với `PGSSLMODE=verify-full` yêu cầu certificate hợp lệ và hostname khớp; nếu không xác minh được certificate thì dừng, không hạ xuống `prefer`/`disable`. [PostgreSQL libpq SSL](https://www.postgresql.org/docs/18/libpq-ssl.html), [libpq connection parameters](https://www.postgresql.org/docs/18/libpq-connect.html).

```powershell
$exportHost = Read-Host 'Verified Development DB host from Supabase Connect'
$exportPort = Read-Host 'Verified port from Supabase Connect'
$exportUser = Read-Host 'Verified DB user from Supabase Connect'
$exportFile = Read-Host 'Absolute SQL file path outside the repository'
$env:PGSSLMODE = 'verify-full'
$env:PGSSLROOTCERT = 'system'
& 'C:\Program Files\PostgreSQL\18\bin\pg_dump.exe' `
  --host $exportHost --port $exportPort --username $exportUser `
  --dbname postgres -W --schema-only --no-owner `
  --schema public --file $exportFile
```

Trước khi chạy, Owner xác nhận target reference ID, mode/host/port, tài khoản có quyền export, file path ngoài repo và terminal không bật command tracing. Chỉ nhập mật khẩu vào prompt của `pg_dump`, không paste vào lệnh, chat, Git hoặc file script. `--schema-only` loại table rows; không dùng `--data-only`, `--clean`, `--no-acl`, `pg_dumpall --globals-only` hoặc `--disable-row-security`. Bản plain SQL có thể chứa GRANT/RLS và function/comment nên chỉ lưu ở nơi bảo mật. [PostgreSQL pg_dump](https://www.postgresql.org/docs/18/app-pgdump.html).

## 3. Export status

**BLOCKED / NOT RUN.** Không có `pg_dump` exit code, file size, checksum hoặc kết quả TLS vì không có kết nối. Không tuyên bố export PASS. Nếu Owner thực hiện lệnh riêng, cần ghi lại exit code và checksum **không chứa nội dung dump**, rồi chuyển sang bước rà soát bảo mật; không tự động restore.

## 4. Schema inventory và baseline đối chiếu

Theo DB-03 ngày trước, `public` có sáu bảng nghiệp vụ: `profiles`, `products`, `locations`, `inventory_items`, `warehouse_orders`, `warehouse_order_items`; thêm `your_table`. Đây là **inventory lịch sử**, chưa phải inventory xác minh từ dump mới. DB-04A mô tả Prisma mapping: `profiles` liên hệ `auth.users`, `locations` dùng `*_code`/`location_barcode`, `inventory_items` có unique `(product_id, location_id, lot_number)` và `expiry_date date`, `warehouse_orders` chưa có `approved_by`, type/status là text. Flutter DTO dùng các cột này. DB-04B cần thêm `stock_ledger`, `idempotency_keys`, nullable `approved_by` và RLS/grants mới. Không coi Prisma model là bản sao đầy đủ của Cloud.

Khi có dump đã rà soát, cần so sánh column name/type/nullability/default, PK/FK/CHECK/UNIQUE, index definitions/predicates, RLS enabled/forced, policies, triggers, function bodies, extensions, owner, grants và default privileges cho sáu bảng. Không chạm `your_table`.

## 5. Security review — chưa thể thực hiện

Không có raw dump nên các kiểm tra dưới đây **NOT RUN**. Người được Owner chỉ định phải giữ bản gốc ngoài Git và kiểm tra: không có `COPY ... FROM stdin`, `INSERT INTO`, table rows, `auth.users` records, token/password; rà soát function definitions, comments, view definitions, GRANT/RLS và endpoint/secret hardcoded. Rà soát thủ công, vì grep đơn giản không chứng minh sạch. Không in các dòng nghi là secret ra logs/chat, không tải dump lên dịch vụ khác. Có thể chia sẻ chỉ báo cáo kiểm tra và bản SQL đã redacted theo quy trình được Owner chấp thuận. Schema-only là metadata, **không phải backup dữ liệu đầy đủ**.

## 6. Missing dependencies

Export đầu tiên chỉ `public` để giảm phạm vi. Cần kiểm tra FK `profiles.id → auth.users(id)`, các policy/function gọi `auth.uid()` hoặc object `auth` khác, và extension schemas/function dependencies. [PostgreSQL pg_dump](https://www.postgresql.org/docs/18/app-pgdump.html) cảnh báo lọc `--schema` không tự kéo object phụ thuộc ngoài schema chọn. Nếu dependency closure yêu cầu `auth`, trước khi export thêm phải kiểm tra quyền đọc, function/comments và object Supabase-managed; chỉ export schema-only phần đã được Owner xem xét. Bản public-only chưa được coi là restore-ready. Cần catalog report riêng cho owners, role names/privileges (không password hashes), extension name/version/schema và migration history metadata; không xuất rows nghiệp vụ hay `auth.users` records.

## 7. PostgreSQL version compatibility

Cloud 17.6 theo DB-03, chưa xác minh lại; `pg_dump` local 18.3 và PostgreSQL local 18.3. [Tài liệu PostgreSQL](https://www.postgresql.org/docs/18/app-pgdump.html) cho phép client `pg_dump` mới dump server cũ; điều đó không bảo đảm dump nạp được vào server 17 sau này. Restore local 18 (nếu được phê duyệt ở task khác) chỉ mang tính provisional; cần kiểm thử cuối trên PostgreSQL 17/Supabase Local tương thích, nhất là extensions, roles, RLS và functions.

## 8. Restore readiness

**NOT READY.** Chưa có dump, security review hoặc dependency closure. Không chạy restore vào `inventoryassistant_migration_test`; Owner đã xác minh local DB ở task trước nhưng agent chưa có local password để tự xác minh. Không chạy migration 001/002. Khi dump được duyệt: kiểm tra host/database local ngay trước thao tác ghi, xác nhận target rỗng, dependencies/roles/extensions, so sánh metadata, rồi xin gate riêng cho TASK-DB-04C-04. [PostgreSQL pg_restore](https://www.postgresql.org/docs/18/app-pgrestore.html) cảnh báo restore có thể thực thi code từ dump; phải duyệt nội dung trước.

## 9. Git status

Chỉ báo cáo đã rà soát này được commit/push lên `feature/backend-nestjs-init`. Commit hash xem qua `git log -1 --oneline` sau commit vì file không thể chứa hash của chính nó. Không stage năm migration SQL chưa track hoặc tài liệu kế hoạch chưa track; không commit raw dump/secrets, không force push/merge/push main.

## 10. Next approval gate

Project Owner thực hiện hoặc tổ chức export bằng command ở mục 2 sau khi tự xác minh target và phương thức xác thực; cung cấp **chỉ** trạng thái, checksum và metadata/dump đã rà soát qua kênh an toàn. Sau khi export và security review thực sự hoàn tất, mới đề xuất **TASK-DB-04C-04 — Local Baseline Restore** để Owner phê duyệt riêng. Không tự restore hoặc triển khai Cloud migration.
