# TASK-DB-04D-B6 — Inventory workflow integrity & security

Ngày 13/11/2026. Branch `feature/backend-nestjs-init`. Công việc **offline**: không kết nối Supabase Cloud, không chạy migration/restore, không đổi Flutter hoặc cấu hình Cloud, không bật route ghi. Trạng thái trước task: tracked tree sạch; năm SQL chưa track trong `supabase/migrations/` và tài liệu kiến trúc chưa track của Owner được giữ nguyên.

## 1. Files changed

| File | Nội dung |
| --- | --- |
| `backend/src/inventory-contract/order-confirmation.service.ts` | Contract và service xác nhận inbound/outbound; validation, ownership, state guard, idempotency, thứ tự lock và ledger. |
| `backend/src/inventory-contract/prisma-order-confirmation.adapter.ts` | Prisma interactive transaction adapter; query tagged/parameterized, `FOR UPDATE`, status CAS, bounded retry. |
| `backend/src/inventory-contract/prisma-inventory-transaction.adapter.ts` | Export port B4 để adapter B6 tái dùng claim/update/ledger cùng transaction client. |
| `backend/src/inventory-contract/*confirmation*.spec.ts` | Unit và SQL-shaped mock tests. |
| `backend/test/app.e2e-spec.ts` | Mock E2E xác nhận route ghi chưa được đăng ký trong AppModule. |
| `backend/src/inventory-contract/README.md` | Trạng thái B6 và giới hạn runtime. |
| Báo cáo này | API/cutover map và release gates. |

Không sửa Prisma schema, SQL candidate, Flutter hoặc AppModule.

## 2. Business rules và state contract

Chỉ nhận phiếu `DRAFT` có `type` khớp `INBOUND`/`OUTBOUND` và `created_by` đúng UUID chủ thể trong JWT đã xác minh. Ngay cả ADMIN/MANAGER cũng chưa được xác nhận phiếu của người khác; policy ủy quyền khác cần Owner duyệt. Phiếu `COMPLETED` hoặc sai type/status bị chặn. Chỉ hỗ trợ **DRAFT → COMPLETED** vì hai confirm action Flutter hiện tại dùng DRAFT; `CONFIRMED`, `CANCELLED`, approval và reservation transition chưa đủ contract để triển khai an toàn.

Mọi dòng phải có UUID product/location, location không NULL, `expected_quantity` và `actual_quantity` là số nguyên dương, lot NULL hoặc chuỗi có giá trị, expiry hợp lệ. Product/location FK được kỳ vọng từ schema hiện có nhưng phải kiểm tra lại trên PostgreSQL thật. Inventory identity là `(product_id, location_id, lot_number)` và expiry phải khớp; yêu cầu **đúng một** `inventory_items` hiện có. Nếu không có hoặc có nhiều dòng (đặc biệt `lot_number NULL` vì UNIQUE trong PostgreSQL cho phép nhiều NULL), toàn bộ lệnh fail closed. B6 **chưa tạo inventory item mới**; cần quyết định business rule lot/expiry, unique identity và concurrent create trước khi hỗ trợ. Không tự giới hạn `actual <= expected`: nghiệp vụ over/under receipt chưa được Owner xác nhận, nhưng actual phải dương.

Outbound lấy `actual_quantity`, tính delta âm, yêu cầu balance mới không âm và không thấp hơn reserved. Không dùng `GREATEST(0, ...)`; thiếu stock phải trả lỗi. Inbound lấy delta dương và kiểm int4 overflow. Cùng một inventory identity xuất hiện nhiều dòng được xử lý theo thứ tự cố định, mỗi dòng có một ledger event với balance sau dòng đó.

## 3. Transaction boundaries và consistency

Service xác minh principal **trước** transaction. Trong một Prisma interactive transaction `Serializable` (maxWait 2s, timeout 10s, `lock_timeout` 3s): claim idempotency → khóa phiếu `FOR UPDATE` → kiểm ownership/type/status → khóa các order lines `ORDER BY id FOR UPDATE` → sắp theo product/location/lot/line ID → khóa từng inventory identity `ORDER BY id FOR UPDATE` → update stock → insert ledger → CAS `warehouse_orders.status = DRAFT` sang COMPLETED → complete claim → COMMIT. Mọi thao tác dùng cùng `tx`. Nếu validation, ledger, status update hoặc claim completion lỗi, transaction phải rollback; mock chỉ mô phỏng điều này, chưa kiểm bằng PostgreSQL.

Hai request cùng phiếu nhưng key khác nhau phải tuần tự tại row lock của order; request thứ hai thấy COMPLETED và rollback claim. Cùng key/scope/request hash replay response nhỏ `{orderId,movements}`; khác method/path/hash conflict; key expired không tái sử dụng. Claim scope per-user lấy từ principal. Status guard là business-event protection hiện tại; chưa có unique `(order_id, order_item_id, event_type)` ở ledger. Vì ledger không có `order_item_id`, sau này cần thiết kế event uniqueness riêng nếu có command khác tạo ledger cho cùng phiếu. Retry chỉ P2034 hoặc P2010 SQLSTATE 40001/40P01/55P03, tối đa ba transaction; không retry lỗi nghiệp vụ. Cần test thật cho unique-key wait, deadlock, serializable retry, row lock và commit uncertainty.

## 4. Security guarantees và giới hạn

`OrderConfirmationService` dùng `VerifiedPrincipalProvider` B5, không đọc actor/scope/role từ body. Không có trusted role thì fail closed; `profiles.role` không dùng làm authorization do sáu policy/grants hiện tại rộng. Auth guard/provider và adapter **chưa wire** vào AppModule; B6 không tạo production controller. Không cấp Flutter quyền ghi trực tiếp vào `stock_ledger`/`idempotency_keys`. 001 candidate chỉ tạo/revoke bảng nội bộ, chưa harden sáu bảng cũ hoặc RPC.

Role `wms_backend` tương lai cần quyền SELECT/UPDATE phù hợp trên `warehouse_orders` (kể cả `SELECT FOR UPDATE`), SELECT và quyền khóa row trên `warehouse_order_items` (`FOR UPDATE` có thể đòi UPDATE privilege theo PostgreSQL), SELECT/UPDATE `inventory_items` theo cột được dùng, INSERT `stock_ledger`, SELECT/INSERT/UPDATE `idempotency_keys`, USAGE schema, và RLS policy phù hợp nếu không dùng BYPASSRLS. Cần test generated Prisma SQL và RETURNING dưới role thật; không cấp quyền Cloud ở B6. `created_by` có thể NULL trên phiếu cũ nên các phiếu đó bị chặn, không tự gán owner.

## 5. Inbound workflow

Inbound hiện tại trong Flutter chỉ cập nhật status, không cộng tồn/ledger. Contract B6 xác nhận order DRAFT và mọi line hợp lệ, khóa inventory item hiện có, cộng `actual_quantity`, ghi ledger INBOUND rồi hoàn tất phiếu trong transaction. Nếu một line không khớp identity hoặc thiếu item, không chuyển status. **Không hỗ trợ nhận SKU/lot mới** cho đến khi có thiết kế create inventory item và unique NULL-lot rõ ràng.

## 6. Outbound workflow

Outbound Flutter gọi RPC `confirm_outbound_order`; snapshot DB-04C-03B cho thấy RPC có thể trừ lặp, dùng `GREATEST(0, ...)`, không ghi ledger và cấp EXECUTE rộng. B6 contract khóa phiếu/stock, kiểm available, trừ đúng lượng thực, ghi ledger OUTBOUND, hoàn tất status. Không bật song song RPC và NestJS; trước cutover cần Owner duyệt thay thế/thu hồi đường RPC và kiểm live function/grants. B6 không sửa RPC.

## 7. Flutter → REST contract đề xuất (chưa implement)

| Flutter action | REST dự kiến | Service / DB boundary | Gate |
| --- | --- | --- | --- |
| `confirmInbound(orderId)` | `POST /api/v1/orders/{id}/confirm-inbound` với `Authorization: Bearer`, `Idempotency-Key` | `OrderConfirmationService.confirm(type=INBOUND)` → một transaction order/stock/ledger | Có chính sách tạo inventory item, 001 + role + PG17 tests; tắt direct status update cùng cutover. |
| `confirmOutbound(orderId)` | `POST /api/v1/orders/{id}/confirm-outbound` với cùng headers | `confirm(type=OUTBOUND)` → một transaction order/stock/ledger | Audit/tắt RPC cùng cutover, thử available/lock/retry trên PG17. |
| `createInboundOrder`, `addOrderItem`, `createOutboundOrder` | `POST /api/v1/orders` / `POST /api/v1/orders/{id}/items` hoặc atomic draft save | Chưa implement trong B6 | Cần contract draft, order code uniqueness và ownership. |

Body confirm không mang userId, role, stock balance hoặc lines; DB là nguồn dòng phiếu. Response dự kiến `{orderId,movements}`; lỗi map riêng thành 401/403/409/422 ở controller tương lai, không lộ nội dung DB. UI Flutter chỉ cập nhật từ response/refresh sau khi chuyển; hiện không sửa Flutter.

## 8. Test results

| Gate | Kết quả | Giới hạn |
| --- | --- | --- |
| Prisma validate/generate | PASS/PASS | Offline, không DB |
| Lint/build | PASS/PASS | TypeScript |
| Unit `npm run test` | PASS, 75/75 | Fake transactional runner và SQL-shaped Prisma mock |
| Mock E2E `npm run test:e2e` | PASS, 6/6 | Chỉ xác nhận route ghi chưa được bật; không mô phỏng endpoint confirmation |
| `git diff --check` | PASS | Whitespace |

Unit bao phủ inbound/outbound success, insufficient available stock, same-key replay, changed request conflict, completed order với key mới, wrong status/type, null location, duplicate NULL-lot inventory, expiry mismatch, missing inventory, empty/zero lines, unauthorized principal/owner, multi-line balances, fake rollback và concurrent queue. Adapter mock kiểm một transaction, tagged SQL và update count. Đây **không** phải PostgreSQL integration hoặc chứng minh rollback/lock thực tế.

## 9. PostgreSQL integration còn thiếu

Chưa chạy trên PostgreSQL 17: schema 001, FK/CHECK/trigger, `SELECT FOR UPDATE` và quyền role, `IS NOT DISTINCT FROM` với NULL, transaction rollback sau ledger/order lỗi, unique claim wait, hai key cùng order, multi-order lock ordering, retry P2034/SQLSTATE, pooler timeout, RLS, default privileges, append-only trigger, các phiếu cũ không có owner. Không tuyên bố Cloud migration hay concurrency PASS.

## 10. Cloud release blockers

- Owner duyệt canonical migration 001 và Supabase migration history; Cloud chưa có `stock_ledger`, `idempotency_keys`, `approved_by` theo preflight trước.
- Backup CUSTOM đọc được nhưng chưa restore thử; kiểm thêm Storage object recovery.
- Cấp và kiểm `wms_backend` role, hạn chế RLS/grants sáu bảng cũ và chặn client tamper `profiles.role`.
- Xác minh/provision `app_metadata.wms_role` bằng authority server-controlled và kiểm phiên/JWT thực tế.
- Audit live RPC `confirm_outbound_order`, dừng đường ghi cũ khi bật endpoint mới; audit Edge Function draft order.
- Quyết định lot NULL, expiry, new inventory item, reserved stock, over-receipt, order approval/status policy; chạy PG17 integration trước Cloud write.

**No-Go** release/cutover. B6 chỉ cung cấp implementation chưa wire và bằng chứng offline.

## 11. Next task và Git

Task tiếp theo: chốt contract inventory identity/order state với Owner, thêm integration harness PostgreSQL 17 + role/RLS và backup restore assurance, rồi trình migration/role/cutover riêng. Không tự thực thi Cloud write. Chỉ commit/push file B6 lên `feature/backend-nestjs-init`; giữ nguyên untracked Owner SQL/tài liệu, không stage dump/backup/secret. Commit hash và push status xác nhận trong phản hồi cuối.
