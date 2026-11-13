# TASK-DB-04C-03B — Rà soát schema-only dump

Ngày 13/11/2026. **Kết luận: CONDITIONAL — chưa sẵn sàng restore local.** Chỉ đọc file dump tại `D:\secure-review\inventoryassistant_schema_only.sql`; không kết nối Cloud/local DB, không restore, migration hoặc sửa Prisma/Flutter. Không đưa raw dump vào Git.

## 1. File integrity

File tồn tại, kích thước **19.514 bytes**, SHA-256 **`89D87CB445A93CDF946B81A136C2DF9DA18752EDA49214208B6A578A335DF55D`**; cả hai khớp Project Owner cung cấp. `pg_dump` 18.3 và exit code 0 là thông tin Owner cung cấp; agent không tự chạy export hoặc xác minh source server live. Parser PostgreSQL đọc 119 statements sau khi bỏ hai dòng meta `\restrict`/`\unrestrict` (giữ nguyên dump gốc). Đây là kiểm tra cấu trúc tĩnh, không phải SQL execution.

## 2. Security findings

- Không thấy `INSERT INTO`, `COPY ... FROM stdin`, `\copy`, auth.users rows, URL ngoài, credential assignment, JWT-like token hoặc chuỗi base64 dài. Có một schema comment ngắn; hai function bodies không chứa chỉ báo URL/secret nêu trên. Không thấy `SECURITY DEFINER`. Quét tự động không chứng minh tuyệt đối không có thông tin nhạy cảm; bản gốc tiếp tục ở ngoài Git.
- `public.confirm_outbound_order` là function có side effect: cập nhật `inventory_items` và `warehouse_orders`. Không thấy `auth.uid()`, `FOR UPDATE`, hoặc negative-stock guard rõ ràng trong body. Function này được GRANT EXECUTE cho `anon`, `authenticated`, `service_role`; vì là security invoker theo DDL, quyền thực tế còn phụ thuộc RLS/ACL của caller. Cần audit nghiệp vụ và concurrency riêng; task này không đổi function.
- Bốn trigger `update_*_updated_at` gọi `public.update_updated_at_column` trên `inventory_items`, `products`, `profiles`, `warehouse_orders`. Function thứ hai không phải `SECURITY DEFINER`; EXECUTE cũng được grant rộng cho ba role trên. Không thấy trigger trên `locations` hay `warehouse_order_items`.
- Sáu bảng nghiệp vụ đều bật RLS và có policy `FOR ALL TO authenticated USING (true) WITH CHECK (true)`. Đồng thời dump có GRANT ALL trên các bảng cho `anon`, `authenticated`, `service_role`. Do đó `authenticated` có quyền đọc/ghi rất rộng theo DDL hiện tại; với `anon`, RLS không có policy áp dụng cho sáu bảng nên truy cập hàng thông thường bị chặn theo default-deny, nhưng GRANT vẫn là bề mặt quyền cần rà soát. `your_table` bật RLS, không thấy policy; bảng và sequence cũng có GRANT rộng. Không thay đổi Cloud/RLS trong task này.
- Dump chứa 24 lệnh ALTER DEFAULT PRIVILEGES cho sequence/function/table và ACL cho role Supabase. Khi tạo bảng mới, cần kiểm chứng grant mặc định rồi REVOKE rõ ràng như thiết kế DB-04B; không dựa vào RLS đơn độc.

Không in giá trị nghi là secret hay nội dung function/comment trong báo cáo. Không upload dump ra dịch vụ bên ngoài.

## 3. Public schema inventory

Dump chứa đúng sáu bảng nghiệp vụ đã nêu ở TASK-DB-03 và `your_table`; **không** chứa `stock_ledger`, `idempotency_keys` hoặc cột `warehouse_orders.approved_by` (đúng với baseline trước DB-04B). Không có standalone `CREATE INDEX`; các index hiện thấy được tạo ngầm bởi PK/UNIQUE constraints.

| Bảng | Cột/kiểu đáng chú ý | PK/UNIQUE, CHECK |
| --- | --- | --- |
| `profiles` | `id uuid` không có DB default; `full_name text NOT NULL`, `role text DEFAULT STAFF`, `phone_number text NULL`, timestamps | PK `id`; role whitelist CHECK |
| `products` | `sku`, `barcode`, `name` text NOT NULL; `unit text DEFAULT Pcs`, `min_safety_stock int4 DEFAULT 0` | PK `id`; UNIQUE `sku`, `barcode` |
| `locations` | bốn `*_code` text NOT NULL, `location_barcode` text, `max_capacity_kg numeric NULL` | PK `id`; UNIQUE `location_barcode` |
| `inventory_items` | `lot_number text NULL`, `expiry_date date NULL`, quantities int4 DEFAULT 0 | PK `id`; UNIQUE `(product_id,location_id,lot_number)`; CHECK `quantity_on_hand >= 0`, `quantity_reserved >= 0`; **chưa có** `quantity_reserved <= quantity_on_hand` |
| `warehouse_orders` | `type`, `status` text; `status DEFAULT DRAFT`, `created_by uuid NULL` | PK `id`; UNIQUE `order_code`; type/status whitelist CHECK |
| `warehouse_order_items` | `expiry_date date NULL`, `location_id uuid NULL`, `expected_quantity`, `actual_quantity` int4 | PK `id`; CHECK expected > 0, actual >= 0 |
| `your_table` | `id int8` identity, `created_at timestamptz` | PK `id`; giữ nguyên |

Các `id` UUID của bảng nghiệp vụ trừ `profiles` có default `gen_random_uuid()`; timestamp tạo/cập nhật dùng `now()` theo DDL. Dump có **7 foreign keys**: inventory → products/locations (`ON DELETE CASCADE`), profiles.id → `auth.users.id` (`CASCADE`), order items → locations (`SET NULL`), orders (`CASCADE`), products (`RESTRICT`), và warehouse_orders.created_by → `auth.users.id` (`SET NULL`). RLS của sáu bảng được nêu ở mục 2. Không có `CREATE EXTENSION` trong phạm vi dump `public`; điều này **không** chứng minh Cloud không dùng extension ở schema khác.

## 4. Dependencies ngoài public

`auth.users` là đích của **hai FK** (`profiles.id`, `warehouse_orders.created_by`) nhưng không có trong dump public-only. Không thấy `auth.uid()` trong sáu policy hoặc hai function được xuất; policy hiện tại dùng `true`. Vẫn cần đánh giá schema `auth` và các object Supabase-managed trước restore. `gen_random_uuid()` có trong default; PostgreSQL 18 có core function, nhưng extension inventory của Cloud chưa được xuất. Role `anon`, `authenticated`, `service_role` và ACL/default privileges là dependencies của restore; vanilla local PostgreSQL có thể thiếu chúng. `--no-owner` loại owner-setting khỏi file, nên **không thể xác minh ownership gốc** bằng dump này. `public` schema có thể đã tồn tại ở database local; restore nguyên file có thể xung đột. [PostgreSQL pg_dump](https://www.postgresql.org/docs/18/app-pgdump.html) lưu ý schema-filter không tự kéo dependencies khác schema.

## 5. Prisma compatibility

Tên cột và kiểu chính của sáu model hiện hữu phù hợp với Flutter DTO (`*_code`, `location_barcode`, `lot_number`, `expiry_date date`, `phone_number`, order text fields). Các khác biệt cần ghi nhận trước khi coi Prisma là mapping chính xác:

1. `WarehouseOrder.creator` trong Prisma tham chiếu `Profile`, nhưng FK thực tế của `warehouse_orders.created_by` tham chiếu **`auth.users`**. UUID có thể trùng trong luồng hiện tại, song quan hệ/FK deletion semantics không tương đương.
2. Prisma khai báo `InventoryItem.product` và `.location` `onDelete: Restrict`; dump dùng **CASCADE** cho cả hai. Đây là khác biệt hành vi khi xóa, không chỉ tên index.
3. Prisma `Profile.id @default(uuid())` có default phía Prisma, còn cột DB `profiles.id` **không có default**. Việc insert trực tiếp phải cung cấp ID.
4. Prisma khai báo nhiều `@@index` thường (product SKU/barcode, location barcode, inventory FK, order type/status, order-item FK); dump không có standalone index tương ứng, dù UNIQUE/PK tạo index ngầm cho một số cột. Không chạy Prisma Migrate để tự đồng bộ.
5. `StockLedger`, `IdempotencyKey` và `WarehouseOrder.approvedBy` trong Prisma là model/cột **dự kiến** của DB-04B, chưa tồn tại ở baseline; Prisma Client không được dùng cho chúng trước migration.
6. DB-04B `002_inventory_checks_optional.sql` sẽ thêm lại **hai CHECK không âm đã tồn tại**, chỉ constraint `reserved <= on_hand` là thiếu. Cần sửa thiết kế 002 ở task được phê duyệt trước khi áp dụng, tránh ràng buộc trùng tên/logic và rà soát dữ liệu cũ.

Không sửa Prisma schema hoặc SQL trong task này.

## 6. Local restore blockers

**CONDITIONAL, chưa READY FOR LOCAL RESTORE REVIEW:** thiếu định nghĩa `auth.users`; thiếu kiểm kê các role, grants/ownership và extensions; chưa xác minh database local rỗng; chưa rà soát hiệu quả khôi phục các Supabase-managed function/ACL trên vanilla PostgreSQL 18; chưa đối chiếu Cloud metadata live sau export. Dùng chính dump public-only sẽ lỗi ở FK `auth.users` nếu dependency chưa có; grants có thể lỗi nếu thiếu role. `CREATE SCHEMA public` cũng có thể xung đột nếu local đã có. Không tạo role giả hoặc bỏ ACL/FK để nhận kết quả PASS; như vậy không còn baseline tương đương. PostgreSQL local 18.3 chỉ cho kết quả provisional so với Cloud 17.6.

## 7. Restore plan — chưa thực thi

1. Owner duyệt bản dump và nguồn metadata phụ trợ. Lấy **schema-only** cho phần `auth`/dependencies cần thiết hoặc dùng Supabase Local có các object managed; không xuất rows/auth.users records. Lấy owner/role/extension catalog metadata riêng, không password hashes. Rà soát bảo mật bản bổ sung giống mục 2.
2. Trong task riêng, xác minh `127.0.0.1:5432`, database `inventoryassistant_migration_test`, phiên bản và trạng thái rỗng bằng query read-only ngay trước write; không dùng Cloud credentials cho local.
3. Lập restore plan có thứ tự: chuẩn bị roles/extensions đã duyệt → auth dependencies → public schema/tables/functions → FK/PK/index/triggers/RLS → GRANT/default privileges. Xử lý `public` schema đã tồn tại và owner khác biệt một cách có ghi chép; không chạy dump nguyên trạng khi prerequisites thiếu. Không động `your_table` ngoài tạo cấu trúc baseline nếu được duyệt.
4. Restore chỉ sau phê duyệt riêng TASK-DB-04C-04; kiểm tra catalog và Prisma mapping sau restore, kiểm thử quyền theo role không bypass RLS. Chưa chạy migration 001/002 ở bước này. [PostgreSQL pg_restore](https://www.postgresql.org/docs/18/app-pgrestore.html) cảnh báo restore có thể thực thi code từ dump, nên luôn duyệt function bodies trước.

## 8. Git status

Đầu task: `feature/backend-nestjs-init`, HEAD/upstream `433d22dd806562c7e88c9cd1395e807aaa6c1cbb`, tracked diff rỗng; năm SQL `supabase/migrations/` và tài liệu kế hoạch vẫn chưa track. Chỉ báo cáo này được commit/push lên feature branch; raw dump nằm ngoài repo. Hash của commit báo cáo xem bằng `git log -1 --oneline` sau commit. Không force push, merge hoặc push main.

## 9. Approval gate cho TASK-DB-04C-04

Owner cần duyệt cách có được `auth.users` schema-only, role/extension metadata, lựa chọn Supabase Local hay vanilla PostgreSQL với prerequisite được quản lý, và xử lý chênh lệch Prisma/FK/RLS nêu trên. Sau khi dependency closure và security review bổ sung đạt, mới trình kế hoạch restore local cụ thể để phê duyệt. **Task này dừng tại rà soát; không restore hoặc chạy migration.**
