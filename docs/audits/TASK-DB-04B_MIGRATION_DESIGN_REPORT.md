# TASK-DB-04B — Safe migration design and offline validation

Ngày: 13/11/2026. Branch: `feature/backend-nestjs-init`. **Chỉ thiết kế offline; không kết nối hoặc ghi Supabase Cloud.**

## 1. Existing database baseline

TASK-DB-03 là bằng chứng read-only gần nhất: `public` có sáu bảng nghiệp vụ `profiles`, `products`, `locations`, `inventory_items`, `warehouse_orders`, `warehouse_order_items` và bảng `your_table`. TASK-DB-04A căn chỉnh Prisma theo các bảng này; hai model `StockLedger`/`IdempotencyKey` khi đó chỉ là placeholder chưa có bảng. Báo cáo cũ không chứng minh trạng thái Cloud tại ngày báo cáo này; cần preflight lại trong một giai đoạn được phê duyệt. Không xóa hay sửa `your_table`.

Git không track migration nào trước task này (`git ls-files supabase backend/prisma` chỉ có `backend/prisma/schema.prisma`). Working tree ban đầu có năm file `supabase/migrations/*.sql` **chưa track** và tài liệu `docs/KE_HOACH_KIEN_TRUC_TYPESCRIPT_BACKEND_SMART_WMS.md` chưa track. Đây là thay đổi có sẵn của người dùng; không sửa, stage hay push. Năm SQL đó trùng chủ đề với task này nhưng có bất đồng về bảo mật/idempotency và không nên áp dụng cùng bản thiết kế mới.

## 2. Migration strategy and baseline

Đề xuất **Supabase migrations là nguồn lịch sử migration duy nhất** vì Flutter và Supabase đã dùng sáu bảng có sẵn. Prisma schema là mapping/client contract; không khởi tạo Prisma Migrate history song song. SQL trong `backend/sql/task_db_04b/` là **bản thiết kế để review**, không nằm trong thư mục auto-deploy. Sau khi Owner phê duyệt và kiểm thử DB local, chuyển đúng một phiên bản được chọn sang lịch sử Supabase; giải quyết năm SQL chưa track trước đó, tránh hai bộ migration tạo cùng bảng/cột.

Baseline sáu bảng bằng snapshot schema và migration history hiện hữu trên môi trường được phép. Không tạo lại các bảng, không chạy `prisma migrate resolve` trên Cloud. Môi trường local mới cần bootstrap schema baseline từ bản dump schema-only đã rà soát, hoặc có một baseline migration chỉ dùng để tái tạo môi trường mới; không apply baseline CREATE TABLE lên database đang tồn tại. So sánh catalog/defaults/FK/index/RLS với TASK-DB-03 trước khi áp dụng phần tăng thêm. Deployment idempotency đến từ migration history + checksum và kiểm tra đối tượng trước khi chạy; SQL cố ý không dùng `IF NOT EXISTS` để tránh che schema drift. Chạy lại file 001 trực tiếp sẽ báo lỗi và rollback transaction, không được xem là cơ chế rerun.

## 3. SQL migration files

| File | Nội dung | Trạng thái |
| --- | --- | --- |
| `backend/sql/task_db_04b/001_additive_design.sql` | Thêm ledger, idempotency, `approved_by`, RLS và revoke grants | Chỉ thiết kế; chưa chạy DB |
| `backend/sql/task_db_04b/002_inventory_checks_optional.sql` | Ba CHECK `NOT VALID` cho tồn kho | Tách riêng; cần duyệt và preflight |
| `backend/sql/task_db_04b/preflight_read_only.sql` | Inventory violations, NULL-lot duplicates, bảng tồn tại | Chưa chạy DB |

001 là một transaction. Sáu bảng nghiệp vụ là prerequisite. Cột `approved_by uuid NULL` tham chiếu `profiles(id)` với `ON DELETE SET NULL` và index; không backfill hay đổi trạng thái phiếu. Flutter thực tế đọc/ghi tên `approved_by` trong `WarehouseOrderModel`, không dùng `reviewed_by`. Flutter code không thay đổi.

## 4. Stock ledger and Prisma compatibility

`stock_ledger.id` UUID PK; FKs tới `products`, `locations`, `warehouse_orders` (optional), `profiles` (optional), đều `RESTRICT` để giữ dấu vết lịch sử. `delta <> 0`, `balance >= 0`, transaction type whitelist; indexes cho product/location/time, order, location và time. Trigger từ chối UPDATE/DELETE, kể cả writer bình thường; chỉ INSERT qua backend. `balance` là tổng on-hand theo product/location, **không phải số dư theo lot**, vì schema ledger chưa có `lot_number`. Ledger bắt đầu ghi từ khi chức năng backend transaction được triển khai; không giả định các giao dịch cũ đã có lịch sử. `created_by` không xác thực vai trò phê duyệt; backend phải xác thực danh tính.

Trong một ACID transaction: khóa inventory rows liên quan theo thứ tự ổn định (hoặc khóa key product/location), tính tổng trước/sau, kiểm tra đủ stock, cập nhật inventory, ghi ledger với `balance` sau giao dịch và hoàn tất idempotency key trước COMMIT. Hai bút toán transfer cùng transaction. Prisma model khớp tên cột/kiểu và FKs; hướng DESC của composite history index đã khai báo. Trigger/CHECK/RLS là SQL ngoài khả năng biểu đạt đầy đủ của Prisma schema. Hiện NestJS chưa có stock transaction use case, nên đây là contract thiết kế, chưa có runtime đảm bảo ledger tự động đồng bộ.

`idempotency_keys` dùng composite PK `(scope_id, key)`; `scope_id` UUID phải đến từ principal đã xác thực ở server, không tin giá trị client gửi. Có method, path đã chuẩn hóa, SHA-256 canonical request hash, trạng thái `processing|completed`, HTTP code, nullable JSON response, timestamps và expiration. No FK cho `scope_id` vì scope có thể là user hoặc tenant về sau; backend phải ràng buộc loại scope và principal theo endpoint. Prisma model khớp. Không cache token, secrets, PII không cần thiết, raw request body, hoặc phản hồi chứa dữ liệu nhạy cảm. Có thể để `response = NULL` và replay thông qua resource ID nếu endpoint không có safe response payload.

Claim bằng `INSERT ... ON CONFLICT DO NOTHING` trên `(scope_id,key)` **trong cùng transaction** với side effect. Concurrent request cùng key chờ unique conflict/transaction, sau đó đọc row và so method/path/hash: khác fingerprint trả 409; completed cùng fingerprint trả cached safe result; processing tồn đọng xử lý qua timeout/khôi phục có kiểm soát. Chỉ commit `completed` cùng business write; lỗi trước commit rollback cả claim. Không coi retry external side effects là exactly-once. TTL cleanup chỉ xóa completed rows quá hạn sau retention đã duyệt; key có thể tái dùng sau cleanup nên contract retry window phải được công bố. Không lưu committed `processing` lâu dài nếu có thể; monitor stale claims.

## 5. Security / RLS

Hai bảng ở `public` để Prisma mapping hiện hữu hoạt động, nên 001 bật RLS và REVOKE quyền từ `PUBLIC`, `anon`, `authenticated`; **không tạo client SELECT/INSERT/UPDATE/DELETE policy**. Flutter không có direct access, kể cả đọc idempotency response. Không dùng `service_role` trong Flutter. Một role DB riêng của backend được đề xuất: `SELECT, INSERT` trên ledger; `SELECT, INSERT, UPDATE, DELETE` trên keys (DELETE chỉ cho TTL worker); không cấp UPDATE/DELETE trên ledger. Chưa tạo role hoặc grant vì tên/credential chưa được duyệt. Backend hiện có thể dùng connection owner/privileged DB credential, điều này bypass RLS; production cần role riêng, secret manager, kiểm tra RLS và object privileges thực tế, giới hạn exposed schemas/API. Trigger ledger là chốt bổ sung nhưng table owner/superuser vẫn có thể vô hiệu hóa, vì vậy quản trị credential là bắt buộc. Hàm trigger không cấp EXECUTE cho client.

## 6. Inventory constraints

Hiện `lot_number` nullable và UNIQUE `(product_id,location_id,lot_number)` theo PostgreSQL NULL semantics cho phép nhiều hàng cùng product/location với NULL lot. Có thể gây double count và upsert ambiguity; không đổi unique trong task này. Trước quyết định partial unique index hoặc `NULLS NOT DISTINCT`, đếm duplicates và xác định quy tắc nhập hàng không lot, rồi gộp dữ liệu theo kế hoạch riêng.

Ba CHECK dự kiến: `quantity_on_hand >= 0`, `quantity_reserved >= 0`, `quantity_reserved <= quantity_on_hand`. File 002 dùng `NOT VALID` để tránh scan dữ liệu cũ lúc add; ràng buộc **vẫn áp dụng cho INSERT/UPDATE mới**, kể cả update các hàng cũ vi phạm, nên chỉ chạy sau preflight và phân tích Flutter/RPC hiện có. Validate từng constraint sau khi sửa dữ liệu theo task được duyệt. Backend dùng transaction + row lock/atomic conditional update để giữ tồn kho nhất quán; CHECK không tự phòng lost update hoặc ledger mismatch.

## 7. Rollback strategy

Trước COMMIT, lỗi trong 001/002 rollback toàn transaction. Sau khi 001 đã áp dụng, ưu tiên forward fix. Nếu cần rollback: dừng backend dùng bảng mới, lưu snapshot/backup và đánh giá dữ liệu ledger/idempotency, rồi mới lập migration đảo có phê duyệt; drop ledger sẽ mất audit trail nên **không có DROP tự động**. `approved_by` nullable nên Flutter hiện hữu vẫn chạy nếu chưa apply, nhưng không drop cột khi đã có dữ liệu phê duyệt. Với 002, có thể drop ba named CHECK theo migration riêng sau phê duyệt nếu phát hiện phá luồng ghi; không sửa unique và không xóa `your_table`. Rehearse restore trên DB local trước bất kỳ Cloud operation nào.

## 8. Offline test results

| Kiểm tra | Kết quả | Giới hạn |
| --- | --- | --- |
| `npm run prisma:validate` | PASS | Chỉ kiểm tra Prisma schema |
| `npm run prisma:generate` | PASS | Sinh client offline |
| `npm run lint` | PASS | TypeScript lint |
| `npm run build` | PASS | Nest build |
| `npm run test` | PASS, 43/43 | Có 4 guard tests cho migration design; không chạy SQL |
| `npm run test:e2e` | PASS, 5/5 | Mock PrismaService; không kết nối DB |
| PostgreSQL parser `pglast.parse_sql` | PASS, 3/3 files | Parse grammar, không thực thi DDL/PLpgSQL trên server |
| Local PostgreSQL migration/replay/rollback | **CHƯA KIỂM THỬ** | Không có `psql`, PostgreSQL server, Docker hoặc Supabase CLI trong môi trường này |

Kế hoạch local: tạo PostgreSQL/Supabase local riêng, bootstrap baseline schema-only, chạy preflight, áp dụng 001 một lần qua migration runner, verify catalog/FKs/grants/RLS và trigger, chạy concurrent claim/replay tests, kiểm tra retry same/different hash, kiểm tra insert ledger và rejection UPDATE/DELETE, kiểm tra Flutter read/write cũ. Snapshot, thử 002 riêng với dữ liệu sạch và dữ liệu vi phạm, thử rollback/restore. Chạy migration runner lần hai và xác nhận history skip; thử chạy SQL trực tiếp lần hai chỉ để xác nhận fail-safe rollback. Không dùng Cloud trong task này.

## 9. Git commits and push status

Commit implementation: `8386dd7` (`feat(db): design additive ledger and idempotency migrations`). Báo cáo được commit riêng trong cùng feature branch; hash có thể xem bằng `git log -2 --oneline` vì không thể tự ghi hash của chính commit vào file. **Push status: tất cả commit của task trên `feature/backend-nestjs-init` đã được push tới `origin/feature/backend-nestjs-init` sau khi hoàn thành báo cáo.** Không stage các file chưa track có trước task; không push `main`, không force push, không merge.

## 10. Project Owner approval needed before later deployment

1. Chọn Supabase migrations làm lịch sử chính và quyết định xử lý năm SQL chưa track đang trùng nội dung.
2. Duyệt baseline/snapshot thực tế, môi trường local và kết quả integration tests SQL.
3. Duyệt role backend tối thiểu, cách lưu credentials, exposed schema và chính sách không cho Flutter truy cập bảng mới.
4. Duyệt retention/idempotency retry window, safe response payload, phạm vi user/tenant.
5. Duyệt CHECK tồn kho sau audit dữ liệu và quyết định NULL-lot uniqueness.
6. Duyệt lịch triển khai, backup và rollback/forward-fix riêng. **Không tự động triển khai Cloud.**
