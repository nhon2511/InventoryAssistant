# TASK-DB-04D-B2 — Đánh giá sẵn sàng phát hành migration

Ngày 13/11/2026. Branch `feature/backend-nestjs-init`, HEAD trước task `76ddee8`, upstream cùng HEAD. **Kết luận: NO-GO cho Cloud migration.** Task này chỉ đọc file/metadata backup, kiểm tra tĩnh và chạy QA offline; không kết nối Cloud, restore hoặc chạy SQL migration. Năm file `supabase/migrations/*.sql` và tài liệu kiến trúc chưa track của Owner được giữ nguyên, không stage.

## 1. Audit trực tiếp SQL candidate

Đã đọc toàn bộ sáu file ở `backend/sql/task_db_04d_b/`, không chỉ dựa vào báo cáo DB-04D-B. SQL 001 tạo hai bảng sau khi kiểm tra object/dependency, rồi thêm `approved_by`/FK/index, trigger, RLS/revoke trong một transaction. SQL 002 độc lập, chỉ thêm CHECK mới `NOT VALID`. Bốn file SQL parse được bằng `pglast` (grammar máy hiện có, không phải thực thi PostgreSQL 17). Không tạo lại sáu bảng, không thay đổi `your_table`, Auth schema hoặc sáu policy cũ.

| Hạng mục | Kết quả audit | Quyết định trước release |
| --- | --- | --- |
| Thứ tự DDL | FK tham chiếu bảng hiện hữu; table/function tồn tại trước trigger; RLS/revoke sau tạo bảng. `auth.users` được check tồn tại. | Đối chiếu catalog và quyền `REFERENCES` thật trên PG17; DO precondition chưa xác minh đầy đủ cột/type/default/FK/index và role. |
| Ledger referential integrity | FK `inventory_item_id`, product, location, order là `RESTRICT`; actor UUID không FK. `delta <> 0`, `balance >= 0`, loại giao dịch whitelist. | Không có ràng buộc item.product/location = snapshot, balance = on-hand sau giao dịch, sign của delta theo loại, hay event id unique. Cần NestJS transaction/row lock và test; quyết định retention vì FK có thể chặn xóa item/product/location/order. |
| Append-only | BEFORE UPDATE/DELETE và BEFORE TRUNCATE trigger raise exception. | Không cản owner/superuser vô hiệu trigger hoặc ghi trực tiếp; kiểm tra quyền TRUNCATE và trigger thực tế sau deploy. INSERT trùng sự kiện vẫn có thể xảy ra. |
| Idempotency | PK `(scope_id,key)`, hash dạng SHA-256, trạng thái và expiry CHECK, completion CHECK. | Không có use case claim/replay/timeout/cleanup; cùng transaction làm `processing` chưa hiển thị trước COMMIT và request trùng có thể chờ unique lock. Cần quy định wait/timeout, hash conflict, expired-key reuse, giới hạn response cache/PII, atomicity cùng inventory/order/ledger. |
| Approval | Cột nullable, FK `auth.users ON DELETE SET NULL`, partial index; trigger chặn `anon`/`authenticated` tự đặt/đổi approved_by. | Trigger không xác thực quyền duyệt của backend/admin; role `postgres` vượt guard. `authenticated` vẫn có policy ghi rộng trên status và các cột cũ. Flutter hiện không có approval use case. |
| CHECK optional | Không lặp hai CHECK không âm; `NOT VALID` tránh scan validate dữ liệu cũ, nhưng kiểm INSERT/UPDATE mới. | Audit mọi write path, đặc biệt RPC `confirm_outbound_order`; dữ liệu 0 vi phạm ở lần preflight trước không đủ cho release. VALIDATE phải duyệt riêng. |
| RLS/ACL/default privileges | Hai bảng mới ENABLE RLS, không client policy, REVOKE PUBLIC/anon/authenticated/service_role. | Default ACL của `public` đã từng grant rộng; cần postcheck `relacl`, `has_table_privilege`, role inheritance và default ACL. REVOKE không chặn owner hoặc BYPASSRLS. Chưa có policy/grant cho backend role quyền tối thiểu. |
| Locks/PG17 | `lock_timeout=5s`, `statement_timeout=60s`, một transaction. | `ALTER TABLE`/FK/trigger trên `warehouse_orders` và partial `CREATE INDEX` có thể chặn ghi; index không `CONCURRENTLY` trong transaction. Cần đo kích thước/traffic và rehearsal PG17. Parser 18 không chứng minh PG17 execution. |

`preflight_read_only.sql` kiểm tra metadata/count cơ bản nhưng không xác minh client TLS, toàn bộ FK/default ACL/role, Supabase history rows hay checksum. `postcheck_read_only.sql` liệt kê object nhưng chưa assert kết quả, role inheritance, `has_table_privilege`, FORCE RLS, function EXECUTE và quyền backend. Hai script là công cụ hỗ trợ operator, chưa đủ làm release gate tự động. [PostgreSQL GRANT](https://www.postgresql.org/docs/17/sql-grant.html) xác nhận quyền UPDATE cấp ở cấp bảng không thể bị phủ định bằng REVOKE cấp cột, nên approval guard chỉ là lớp bảo vệ có giới hạn.

## 2. Backend database role và quyền đề xuất

`PrismaService` extends `PrismaClient`; `schema.prisma` lấy runtime URL từ `DATABASE_URL` và `directUrl` từ `DIRECT_URL`. Chỉ đọc username của hai URL trong `backend/.env`, không in URL, password, host hoặc project reference: **cả hai dùng role gốc `postgres` (username có hậu tố pooler)**. Không có process-level override khi kiểm tra. Đây là cấu hình file cho môi trường làm việc hiện tại, **không chứng minh role của deployment đang chạy hoặc `current_user` trên Cloud**. `SUPABASE_SERVICE_ROLE_KEY` là API credential, không phải role được Prisma dùng qua PostgreSQL URL. [Supabase roles](https://supabase.com/docs/guides/database/postgres/roles) mô tả `postgres` là role quản trị và `service_role` là role API có BYPASSRLS.

**Tương thích hiện tại:** Prisma bằng `postgres` có thể vượt RLS/revoke của candidate (phải xác minh quyền hiệu lực trên Cloud). Vì vậy candidate không đạt nguyên tắc least privilege cho backend; một key bị lộ có phạm vi ảnh hưởng lớn. Đổi ngay URL sang role riêng cũng **không** hoạt động với SQL 001 hiện tại: hai bảng mới không có backend policy/grant, sáu bảng cũ có RLS policy chỉ cho `authenticated`, và transaction inventory cần quyền trên nhiều bảng. Đây là blocker thiết kế, không phải lỗi QA.

**Phương án cần duyệt ở task khác:** role LOGIN riêng cho NestJS, không owner, không `BYPASSRLS`, chỉ `USAGE` schema cần thiết; `SELECT/INSERT` trên ledger, `SELECT/INSERT/UPDATE/DELETE` trên keys (DELETE chỉ cho TTL cleanup được kiểm soát), `SELECT` trên product/location/order/item và quyền `UPDATE` tối thiểu trên inventory/order theo use case. RLS policy riêng cho role này trên các bảng cần truy cập, hoặc server-side RPC `SECURITY DEFINER` được kiểm toán kỹ với `search_path` cố định và EXECUTE hẹp. Không cấp `UPDATE/DELETE/TRUNCATE` ledger; không cấp quyền hai bảng mới cho Flutter `anon`/`authenticated`. Mọi `REFERENCES`, function/sequence và quyền schema phải kiểm chứng bằng phiên role thực, `has_table_privilege` và RLS tests. Không tạo role/grant/policy trong task này.

## 3. Migration history và năm file chưa track

Theo Owner, `supabase_migrations.schema_migrations` chưa tồn tại. Theo [Supabase CLI](https://supabase.com/docs/reference/cli/introduction), lần `db push` đầu tạo history rồi ghi version sau khi migration thành công; `--dry-run` chỉ liệt kê việc sẽ áp dụng. Không chạy `repair`, `db pull` hoặc `db push` trong task này. `db pull` có thể dùng Docker và tùy chế độ ghi history, nên không coi là một bước read-only mặc định. Bảng business đang có được coi là **legacy baseline đã tồn tại**, không tạo lại bằng SQL 001. Cần lưu snapshot/schema audit và quyết định cách tái tạo môi trường mới ở task riêng; history mới từ additive migration không tự bao phủ các DDL legacy.

**Tuyệt đối không `db push` từ checkout hiện tại:** năm SQL chưa track nằm trong `supabase/migrations/` và có DDL trùng, dù chưa Git track vẫn có thể được CLI quét. Owner phải duyệt cách xử lý, bảo vệ nội dung và dùng clean release checkout chỉ chứa version được duyệt; kiểm `migration list` và `db push --dry-run` phải cho thấy **chính xác một** migration 001, không có năm file cũ, 002, roles hoặc seed. Không sửa/xóa/stage năm file đó trong B2. Không dùng `migration repair` để đánh dấu applied nếu chưa chứng minh catalog tương ứng.

## 4. Backup và recovery

Chỉ đọc metadata tại `D:\secure-review\backups\inventoryassistant_pre_migration_20261113.dump`: file tồn tại, 438301 bytes, header `PGDMP`, SHA-256 quan sát `D40E966DA05C61E8EAE93743BCDD36E068DC26E1D2B01983F37AE7DFFAA8BF27`. **Không có hash kỳ vọng độc lập trong yêu cầu nên chưa thể xác nhận hash khớp một bản chuẩn.** `pg_restore` 18.3 `--list` exit 0, header ghi source PostgreSQL 17.6 và dump tool 18.3; đếm được **711 object entries**, khác 718 entries Owner nêu. Có 54 `TABLE DATA` entries và metadata cho public/auth/storage/vault, nhưng không đọc table rows hoặc secrets. Chênh lệch count cần Owner đối chiếu trước release. `pg_restore --list` chứng minh archive đọc được, **không** chứng minh data completeness hay restore thành công.

Logical database archive không bảo vệ Supabase Storage object bytes; database chỉ chứa metadata của Storage. Cũng cần kiểm tra phạm vi pg_dump/options, global roles/passwords, external services, Auth configuration, Vault/external keys, quyền và tính nhất quán điểm backup. [Supabase backups](https://supabase.com/docs/guides/platform/backups) xác nhận Storage objects không nằm trong DB backup. Chưa có restore rehearsal, kiểm tra row counts/checksums sau restore, Storage object recovery hoặc bằng chứng RTO/RPO. **Recovery readiness: BLOCKED.** Không restore trong task này.

## 5. Prisma, NestJS và Flutter

Prisma hiện map `WarehouseOrder.creator/approver` qua `Profile`, khác FK Cloud/candidate đến `auth.users`; `Profile.id @default(uuid())` khác DB; `InventoryItem` Prisma `onDelete: Restrict` khác FK Cloud CASCADE; `StockLedger` thiếu `inventoryItemId` và còn creator relation Profile; một số index Prisma không có thực tế. `PRISMA_ALIGNMENT_REVIEW.md` chỉ là đề xuất, chưa áp dụng. Prisma validate chỉ chứng minh schema tự hợp lệ, không chứng minh mapping với Cloud. NestJS hiện chỉ có Prisma service/skeleton, chưa có transaction ledger/idempotency/approval hoặc role authorization.

Flutter `WarehouseOrderModel` đọc/ghi `approved_by` nullable; inbound/outbound datasource tạo order không gửi trường này và dùng direct Supabase queries; outbound gọi RPC `confirm_outbound_order`. Không thấy approval workflow trong các feature được rà soát, nên thêm cột nullable không tự tạo nghiệp vụ duyệt. Client vẫn có đường ghi status hiện hữu theo policy rộng; cần smoke/authz test trước release. Không sửa Flutter/Prisma/backend use case trong B2.

## 6. Security risks và stop conditions

STOP nếu project ref/host/port/TLS không khớp, DB version khác, history hoặc catalog drift, năm file cũ còn trong release checkout, grants mặc định làm client truy cập bảng nội bộ, backend role chưa được kiểm chứng, approval guard không đúng với PostgREST role, backup chưa restore được, data count vi phạm, lock rehearsal lỗi, hoặc PG17 test chưa có. Không dùng `service_role` ở Flutter. Cần audit `confirm_outbound_order` hiện có và sáu policy `FOR ALL USING(true)` riêng; 001 không harden các object đó.

## 7. QA offline

| Gate | Kết quả | Giới hạn |
| --- | --- | --- |
| `npm run prisma:validate` | PASS | Không kết nối DB |
| `npm run lint`, `npm run build` | PASS | TypeScript offline |
| `npm run test` | PASS, 43/43 | Unit/mocks |
| `npm run test:e2e` | PASS, 5/5 | Mock-only |
| `pglast.parse_sql` | PASS, 4/4 SQL files | Static syntax bằng parser 18; không thực thi PG17 |
| Static DDL scan | 2 bảng mới, 0 bảng cũ tạo lại, 0 client policy, 1 CHECK optional | Không thay thế catalog/runtime audit |
| `git diff --check` | PASS trước khi viết báo cáo; kiểm lại staged diff trước commit | Whitespace only |

SQL integration, privilege tests, concurrency tests, Cloud migration, recovery rehearsal: **NOT RUN**.

## 8. Release package và lệnh cho Operator — chỉ tài liệu, KHÔNG chạy ở B2

Điều kiện: Owner phê duyệt task thực thi riêng; clean checkout chỉ chứa một migration đã duyệt, CLI version được pin/đọc hướng dẫn đúng version, linked target được xác minh độc lập, backup/recovery/role/PG17 gates PASS. Không truyền password bằng CLI flag hoặc URL trong shell history. Lệnh read-only sau để Operator nhập host/port/user từ màn hình Supabase Connect; không lưu credential trong repo. `PGSSLROOTCERT=system` yêu cầu client PostgreSQL 18 và TLS hostname verification.

```powershell
$devHost = Read-Host 'Verified Development host'
$devPort = Read-Host 'Verified Development port'
$devUser = Read-Host 'Verified Development database user'
$env:PGSSLMODE = 'verify-full'
$env:PGSSLROOTCERT = 'system'
& 'C:\Program Files\PostgreSQL\18\bin\psql.exe' -X -W -h $devHost -p $devPort -U $devUser -d postgres -v ON_ERROR_STOP=1 -f 'backend\sql\task_db_04d_b\preflight_read_only.sql'
```

Operator đối chiếu output với baseline đã ký duyệt, đồng thời cần query bổ sung về SSL client, `pg_roles.rolbypassrls`, `pg_default_acl`, `pg_class.relacl`, `has_table_privilege`, role inheritance, schema/history checksum, index/FK/trigger definitions và số lượng tồn kho vi phạm. Sau khi có migration được Owner duyệt trong clean checkout và **chỉ trong task thực thi riêng**:

```powershell
supabase migration list --remote
supabase db push --dry-run --remote
# Only after explicit Owner approval for this exact target and reviewed plan:
supabase db push --remote
& 'C:\Program Files\PostgreSQL\18\bin\psql.exe' -X -W -h $devHost -p $devPort -U $devUser -d postgres -v ON_ERROR_STOP=1 -f 'backend\sql\task_db_04d_b\postcheck_read_only.sql'
```

Các lệnh CLI trên theo [Supabase CLI reference](https://supabase.com/docs/reference/cli/introduction), chưa chạy hoặc xác nhận version CLI tại máy này. `supabase` hiện không có trong PATH. Không dùng `--include-seed`, `--include-roles`, `--include-all`, `-p`, `--db-url` hoặc `--yes`; review dry-run và dừng nếu liệt kê ngoài migration dự kiến. Postcheck phải có assertions thủ công/độc lập về grants, RLS, role và Flutter/NestJS smoke; script hiện tại chưa đủ.

## 9. Go/No-Go và recovery

**NO-GO.** Blockers bắt buộc: backup không có independent hash/restore assurance và TOC count lệch; Prisma `postgres` quá rộng, role tối thiểu/RLS chưa thiết kế xong; ledger/idempotency chưa có NestJS use case hoặc concurrency test; history baseline và năm file untracked chưa giải quyết; chưa thử candidate trên PG17; lock và Flutter/RPC security chưa được kiểm chứng. Không coi archive readable hay unit tests PASS là migration PASS.

Nếu deployment tương lai lỗi trước COMMIT, transaction rollback và dừng; nếu đã COMMIT, ưu tiên migration forward-fix version mới, không sửa history hoặc DROP audit ledger tự động. Restore chỉ từ backup đã thử, có phạm vi Storage/Auth được Owner duyệt và kế hoạch downtime/RPO/RTO; xem `ROLLBACK_AND_FORWARD_FIX.md`.

## 10. Task tiếp theo và Git

TASK-DB-04D-B3 (thiết kế/kiểm thử release gates): quyết định backend role và policy, hoàn thiện Prisma/NestJS ACID + idempotency/approval, kiểm thử PG17 tương đương hoặc có phương án kiểm chứng khác được Owner chấp thuận, xác minh recovery và đối chiếu TOC/hash, giải quyết năm migration chưa track trong clean release checkout, bổ sung pre/postcheck assertions. Chỉ sau khi các gates PASS mới đề xuất TASK-DB-04D-C với quyền Cloud write **riêng**. B2 không thực thi migration.

Báo cáo này là thay đổi duy nhất của task; commit/push chỉ lên feature branch, không stage các file chưa track của Owner, backup, dump hoặc secrets. Hash và push status được xác nhận trong phản hồi cuối.
