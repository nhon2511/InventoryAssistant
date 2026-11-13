# TASK-DB-04D-A — Supabase Development preflight

Ngày 13/11/2026. **Trạng thái: BLOCKED — chờ kết quả read-only và backup từ Project Owner; KHÔNG ĐƯỢC TRIỂN KHAI MIGRATION.** Owner đã cho phép kiểm tra metadata read-only trên đúng Development project. Agent chưa dùng Cloud credential hoặc kết nối Cloud. Đến lúc chốt báo cáo chưa nhận được output script hoặc trạng thái backup; không ghi project reference ID, connection string, password hoặc bản ghi nghiệp vụ.

## 1. Git baseline

Branch: `feature/backend-nestjs-init`. Trước task, HEAD/upstream cùng ở `c5eb8bf`; tracked diff rỗng. Năm SQL `supabase/migrations/*.sql` và `docs/KE_HOACH_KIEN_TRUC_TYPESCRIPT_BACKEND_SMART_WMS.md` chưa track là thay đổi của người dùng; không sửa/xóa/stage. Hai thiết kế `backend/sql/task_db_04b/001_additive_design.sql`, `002_inventory_checks_optional.sql` đã track. SQL read-only mới tại `backend/sql/task_db_04d_a/cloud_preflight_read_only.sql` được commit/push riêng (`4de2325`) để Owner chạy và gửi kết quả đã rà soát; không chứa credentials.

## 2. Cloud target verification

DB-03 ghi nhận Development project đã được đối chiếu reference ID và kết nối session pooler trong lần audit trước; đó **không phải xác minh live cho task này**. Owner cần đối chiếu reference ID với Dashboard, host/port/user từ màn hình Connect, và TLS trước khi chạy script. Script xuất `database_name`, `server_version`, `database_backend_ssl` nhưng **không** xuất project ID/username. Với session pooler, `pg_stat_ssl` có thể phản ánh hop pooler → database, nên kết quả này không thay thế xác minh TLS phía client bằng `verify-full`. Agent không có credential tương tác, vì vậy không tự kết nối. [Supabase connection modes](https://supabase.com/docs/guides/database/connecting-to-postgres) phân biệt direct/session/transaction pooler. **Kết quả live: chờ Owner cung cấp exit code và xác nhận target khớp.** Nếu target hoặc TLS client không khớp: STOP.

## 3. Current schema

Baseline gần nhất là schema-only dump `public` do Owner xuất ở DB-04C-03B, hash đã khớp: sáu bảng nghiệp vụ và `your_table`; chưa có `stock_ledger`, `idempotency_keys`, `approved_by`. `inventory_items` đã có CHECK `quantity_on_hand >= 0` và `quantity_reserved >= 0`, chưa có `quantity_reserved <= quantity_on_hand`. `profiles.id` và `warehouse_orders.created_by` tham chiếu `auth.users`; Prisma hiện mô tả `WarehouseOrder.creator` qua `profiles`, và `InventoryItem` `onDelete: Restrict` trong khi FK Cloud dump dùng CASCADE. Đây là **snapshot lịch sử**, không chứng minh trạng thái hiện tại.

Script read-only truy vấn table/column/type/nullability/default-presence, FK/PK/UNIQUE/CHECK names, index names/digests, functions/triggers/extensions và tồn tại ba object mới. Aggregate duy nhất trên dữ liệu nghiệp vụ là số cặp product/location trùng NULL lot và ba count vi phạm inventory; không xuất ID, row hoặc dữ liệu cá nhân. **Kết quả schema drift live: chờ Owner.** Mọi object/cột bất ngờ hoặc kết quả aggregate khác 0 cần đánh giá trước migration.

Lệnh dự kiến để **Owner tự chạy** trong terminal mới sau khi đối chiếu project reference ID ở Dashboard; không chạy trong task của agent. `-W` nhập password tương tác, host/port/user được nhập lúc chạy thay vì ghi trong script/history. Nếu TLS verify thất bại, dừng và không hạ mức xác thực.

```powershell
$devHost = Read-Host 'Verified Development DB host from Supabase Connect'
$devPort = Read-Host 'Verified port from Supabase Connect'
$devUser = Read-Host 'Verified DB user from Supabase Connect'
$env:PGSSLMODE = 'verify-full'
$env:PGSSLROOTCERT = 'system'
& 'C:\Program Files\PostgreSQL\18\bin\psql.exe' -X -W `
  -h $devHost -p $devPort -U $devUser -d postgres `
  -v ON_ERROR_STOP=1 `
  -f 'D:\HOC_2026_2027\AIPRODUCT\InventoryAssistant\backend\sql\task_db_04d_a\cloud_preflight_read_only.sql'
```

## 4. Security/RLS findings

Dump DB-04C-03B có RLS enabled trên sáu bảng, policy `FOR ALL TO authenticated USING (true) WITH CHECK (true)` và GRANT ALL cho các role Supabase; đây là quyền rất rộng hiện hữu, không tự thay đổi ở task này. `public.confirm_outbound_order` có thể cập nhật tồn kho và phiếu, được grant EXECUTE cho `anon`/`authenticated`/`service_role`; cần audit nghiệp vụ riêng. Script live trả RLS flags, policy names/roles/boolean/digests và grants, **không** in policy expression hoặc function body. **Kết quả live: chờ Owner.** Với bảng mới, design 001 bật RLS và thu hồi quyền client; kiểm tra default privileges và quyền thực tế sau deployment ở task được duyệt.

## 5. Existing migration history

Không có Supabase migration file nào được Git track trước task này; năm SQL của người dùng vẫn chưa track. Điều đó không chứng minh Cloud migration history rỗng. [Supabase docs](https://supabase.com/docs/guides/deployment/database-migrations) ghi lịch sử trong `supabase_migrations.schema_migrations`; script chỉ kiểm tra tồn tại và liệt kê `version` nếu bảng có, không sửa history. **Kết quả live: chờ Owner.** Nếu history và thư mục migration không khớp, dừng và lập baseline/repair plan riêng; không chạy `migration repair`, `db push` hay Prisma Migrate trong task này.

## 6. Backup readiness

Schema-only dump 19.514 bytes chỉ là cấu trúc, **không phải backup dữ liệu demo/Auth**. Owner cần kiểm tra đúng project trong Dashboard `Database > Backups`: loại daily/PITR, điểm backup gần nhất trước dự kiến triển khai, retention, quyền restore, và bằng chứng restore đã từng kiểm chứng vào project riêng. [Supabase backup docs](https://supabase.com/docs/guides/platform/backups) nêu điều kiện backup phụ thuộc plan; không suy đoán plan của project này. Nếu không có backup có thể phục hồi đã được xác minh, **BLOCKED**. Không xuất dữ liệu thật vào Git, không thực hiện restore hoặc thay đổi Cloud settings trong task này. **Trạng thái backup: chờ Owner.**

## 7. Migration conflict matrix

| SQL chưa track của người dùng | Trùng với design DB-04B | Vấn đề và hướng hợp nhất đề xuất |
| --- | --- | --- |
| `20261113000001_create_stock_ledger.sql` | Ledger của 001 | Thiếu CHECK delta/balance, FK order và append-only trigger; `created_by SET NULL` khác thiết kế giữ audit. Dùng một version có CHECK/FK/trigger, không chạy hai file cùng tạo bảng. |
| `20261113000002_create_idempotency_keys.sql` | Keys của 001 | PK `key` toàn cục, `user_id` nullable, response/status/expiry lỏng hơn composite `(scope_id,key)`; phải chọn một API/Prisma contract rồi đưa vào migration duy nhất. |
| `20261113000003_add_approved_by_to_warehouse_orders.sql` | Cột/FK/index của 001 | Cùng cột; `IF NOT EXISTS` có thể che FK/index drift. Giữ nullable `approved_by` để tương thích Flutter, thêm một lần sau preflight. |
| `20261113000004_add_inventory_constraints.sql` | 002 | Hai CHECK không âm đã tồn tại theo dump; không tạo lại. Chỉ xem xét `reserved <= on_hand` sau count vi phạm và đánh giá tác động write paths. |
| `20261113000005_rls_stock_ledger_idempotency.sql` | RLS/grants 001 | Cho authenticated đọc ledger/keys, trái với deny-by-default của 001; Owner cần duyệt contract quyền trước khi có một migration chính thức. |

Đề xuất **Supabase migration history là nguồn duy nhất**. Không sửa/xóa/stage năm file chưa track trước khi Owner duyệt cách hợp nhất. Không có `DROP your_table` trong kế hoạch, không tạo lại sáu bảng, không chạy Prisma Migrate.

## 8. Final migration/release plan — chỉ đề xuất

1. Operator xác minh target ref/host/port/user/TLS, chạy script `cloud_preflight_read_only.sql` bằng `psql -X -W -v ON_ERROR_STOP=1` trong phiên riêng. Script mở `BEGIN TRANSACTION READ ONLY`, đặt statement timeout 10 giây, lock timeout 3 giây, chỉ SELECT rồi ROLLBACK. PostgreSQL parser đọc được 22 statement, không có AST DDL/DML ghi dữ liệu. Owner rà soát và chỉ chia sẻ metadata/aggregate không nhạy cảm.
2. Đối chiếu kết quả live với dump DB-04C-03B và Prisma/Flutter. Nếu drift, object đã tồn tại, history bất đồng, count vi phạm, RLS/grants bất ngờ hoặc TLS/target không đúng: **dừng**. Duyệt backup/restore readiness trước mọi write.
3. Sau phê duyệt riêng của Owner, thiết kế một bộ migration additive có tên/timestamp không xung đột trong Supabase history: ledger + append-only bảo vệ, scoped idempotency, nullable `approved_by`/FK/index, RLS deny-by-default/revoke grants. Dùng FK thực tế khi liên quan `auth.users`; không đổi Flutter/Auth/workflow state. Rà soát lock time và rollback trước khi triển khai.
4. Tách `reserved <= on_hand` thành migration optional, chỉ sau aggregate preflight và dữ liệu hiện hữu hợp lệ; bỏ hai CHECK trùng. Không đổi unique NULL-lot trong release này. Test code/Prisma contract, mock E2E và smoke Flutter DTO/read/write paths; đánh giá concurrent outbound/ledger/idempotency riêng, không tuyên bố end-to-end PASS khi NestJS chưa có use case.
5. Ở task triển khai được duyệt: một operator chạy migration history đúng một lần; postcheck table/column/FK/index/CHECK/RLS/grants, Prisma query và Flutter smoke. Nếu thất bại trước COMMIT, rollback transaction. Sau COMMIT, ưu tiên forward-fix; không tự DROP ledger/`your_table`. Backup restore là biện pháp riêng có downtime và phạm vi dữ liệu phải được Owner duyệt.

## 9. Risk assessment

Rủi ro cao: target sai, backup chưa kiểm chứng, schema/history drift, RLS/grants hiện hữu quá rộng, function outbound mutating, FK Prisma khác Cloud, hai bộ SQL trùng, CHECK 002 trùng, NULL-lot duplicates, PG17 Cloud chưa qua migration integration test. Script không thay thế backup hoặc dry run. Mọi chỉ báo trên là stop condition trước deployment. Không đưa connection string/password/project ref vào report.

## 10. Approval requirements và Git status

Owner cần cung cấp kết quả script đã rà soát và trạng thái backup của đúng Development project; duyệt phương án hợp nhất năm SQL, quyết định quyền truy cập ledger/keys, xác nhận backup có thể phục hồi và cho phép một task triển khai **riêng**. TASK-DB-04D-A không chạy migration, DDL/DML ghi, thay đổi RLS, `db push` hoặc deploy.

Script read-only đã commit/push ở `4de2325`. Báo cáo được commit riêng trên cùng feature branch; hash của chính commit báo cáo xem bằng `git log -1 --oneline`. Không stage năm SQL chưa track, không commit secrets, không push main, force push hoặc merge.
