# TASK-DB-04D-B5 — JWT authorization và Flutter write-path audit

Ngày 13/11/2026. Branch `feature/backend-nestjs-init`. Đây là kết quả **offline**; không kết nối Supabase Cloud, không chạy migration/restore, không đổi Flutter, RLS/ACL/Auth hoặc bật endpoint inventory. Năm SQL chưa track trong `supabase/migrations/` và tài liệu chưa track của Owner được giữ nguyên.

## 1. Files changed

- `backend/src/auth/supabase-principal.provider.ts`: `VerifiedPrincipalProvider` cụ thể, hai chế độ xác minh JWT.
- `backend/src/auth/authentication.guard.ts`: parser Bearer và authentication guard; trả lỗi 401 chung, không lộ token hoặc nguyên nhân xác minh.
- `backend/src/auth/trusted-roles.guard.ts`: decorator policy và authorization guard; mặc định từ chối nếu thiếu policy/role.
- `backend/src/auth/*.spec.ts`: khóa ES256 thử nghiệm tạo trong test, Auth endpoint mock, guard/RBAC tests.
- `backend/src/inventory-contract/inventory-command.service.ts` và test: bổ sung issuer, audience, nguồn xác minh vào `VerifiedPrincipal`; giữ adapter B4 chưa đăng ký.
- `backend/package.json`, `backend/package-lock.json`: thêm `jose` 6.x.
- Báo cáo này. Không sửa AppModule, Prisma schema, SQL candidate hay Flutter.

## 2. Authentication design và JWT validation

`SupabasePrincipalProvider` nhận URL project HTTPS đã cấu hình phía server, mode và tùy chọn test injection. Nest DI tokens `SUPABASE_AUTH_OPTIONS` và `VERIFIED_PRINCIPAL_PROVIDER` dành cho module tương lai; B5 chưa đăng ký chúng. Mode `jwks` dùng `jose` để xác minh chữ ký ES256/RS256 với JWKS tại issuer `/auth/v1/.well-known/jwks.json`, kiểm `iss`, `aud=authenticated`, `exp`, `nbf`, UUID `sub`, và PostgREST `role=authenticated`. JWKS chỉ được gọi khi có request xác minh; B5 không gọi Cloud. Không chấp nhận `anon`/`service_role` làm access token người dùng. [Supabase signing keys](https://supabase.com/docs/guides/auth/signing-keys), [Supabase JWT](https://supabase.com/docs/guides/auth/jwts).

Mode `auth-server` dành cho legacy symmetric JWT: backend gọi HTTPS `GET /auth/v1/user` với Bearer token và publishable/anon key, timeout mặc định 3 giây, không cache response; chỉ sau HTTP 200 và `user.id === sub` mới đọc claims. Không yêu cầu hay hardcode JWT secret; không dùng `service_role`. Network failure/timeout/non-200 đều fail closed. Chế độ này cần xác minh dự án thực tế đang dùng ký đối xứng trước khi cấu hình. [Supabase getUser](https://supabase.com/docs/reference/javascript/auth-getuser), [Supabase signing keys](https://supabase.com/docs/guides/auth/signing-keys).

JWT signature/expiry check không chứng minh phiên chưa bị thu hồi ngay lúc request. Nếu nghiệp vụ cần bảo đảm đó, thêm bước xác minh Auth `/user` cho cả JWKS mode với timeout và cache rất ngắn hoặc không cache; đánh giá độ trễ, outage và rate limits trước khi bật. JWKS rotation và Auth server thật **NOT TESTED**; mock không chứng minh tương thích Cloud. Không đưa token vào log, report hoặc idempotency response.

`VerifiedPrincipal` gồm `subjectId`, `scopeId` bằng UUID user, `issuer`, `audience`, `authorizationSource`, và `trustedRole` tùy chọn. `scopeId` per-user hiện tại; nếu sau này có tenant, cần nguồn tenant server-controlled riêng, kiểm membership và đổi idempotency scope có kế hoạch. Không lấy actor/scope/role từ request body.

## 3. Trusted role và RBAC

`profiles.role` **không đáng tin**: snapshot DB-04C-03B cho thấy sáu bảng có `FOR ALL TO authenticated USING(true) WITH CHECK(true)` và GRANT rộng. Flutter đăng ký profile với role STAFF, nhưng client đang có thể truy cập trực tiếp bảng theo policy hiện hữu; kiểm tra UI dựa vào `profile.role` không phải server authorization. `user_metadata` cũng có thể do user chỉnh; `app_metadata` do phía quản trị Auth quản lý theo [Supabase user metadata](https://supabase.com/docs/guides/auth/users) và [RLS docs](https://supabase.com/docs/guides/database/postgres/row-level-security).

Provider chỉ nhận `app_metadata.wms_role` thuộc ADMIN/MANAGER/STAFF **nếu** `trustAppMetadataRole=true`. Mặc định không có trusted role. Owner phải xác minh ai có thể provision/update claim, cấm client ghi, cơ chế revoke/refresh token và ánh xạ role trước khi bật. Không tự gán ADMIN/MANAGER. `TrustedRolesGuard` yêu cầu `@RequireTrustedRoles(...)`, từ chối khi thiếu policy, principal hoặc role phù hợp (403). Approval chỉ ADMIN/MANAGER, STAFF không được duyệt; `InventoryCommandService.authorizeApproval` vẫn không sửa phiếu. `JwtAuthenticationGuard` trả 401 chung. Cả hai guard chưa đăng ký vào AppModule/controller; nếu dùng về sau phải gắn authentication trước authorization và test thứ tự thực tế.

## 4. Flutter write-path inventory

Kiểm tra toàn bộ `lib/**/*.dart` cho `.from`, `.insert`, `.update`, `.delete`, `.upsert`, `.rpc`, `functions.invoke`, và Supabase Auth mutations. Bảng sau mô tả **đường remote hiện có**; endpoint là đề xuất, chưa implement.

| File / function | Table/RPC, hành động | Side effect & quyền hiện tại | Endpoint đề xuất / dependency / double-write |
| --- | --- | --- | --- |
| `lib/features/auth/data/datasources/auth_remote_datasource.dart:59` `signUpWithEmail` | Supabase Auth signup rồi `profiles.insert` tại dòng 76 | Tạo user và profile hai bước không nguyên tử; client gửi `role='STAFF'`; policy `authenticated` rộng theo snapshot | Giữ Auth SDK nhưng chuyển provisioning profile sang server/Auth trigger sau audit; chặn client sửa role. Nếu song song trigger và insert sẽ duplicate/error. |
| `lib/features/inbound/data/datasources/inbound_remote_datasource.dart:32` `createInboundOrder` | `warehouse_orders.insert` dòng 39, DRAFT/INBOUND | `created_by` do client gửi; không có server RBAC theo snapshot | `POST /api/v1/orders/inbound`; yêu cầu JWT, ownership, idempotency và atomic order create. Hai đường đồng thời tạo phiếu trùng. |
| Cùng file dòng 55 `addOrderItem` | `warehouse_order_items.insert` dòng 66 | Ghi dòng hàng và lượng thực nhận; không thấy stock update tại datasource này | `POST /api/v1/orders/{id}/items` hoặc atomic draft save; kiểm order/ownership/quantity. Hai đường tạo dòng trùng. |
| Cùng file dòng 84 `confirmInbound` | `warehouse_orders.update status=COMPLETED` dòng 88 | Chỉ đổi status, **không** cộng tồn/ledger trong datasource; policy hiện hữu rộng | `POST /api/v1/orders/{id}/confirm-inbound`; cần transaction order + inventory + ledger và state guard. Giữ hai đường gây completed thiếu ledger hoặc cộng kép. |
| `lib/features/outbound/data/datasources/outbound_remote_datasource.dart:22` `createOutboundOrder` | `warehouse_orders.insert` dòng 29, DRAFT/OUTBOUND | Client gửi `created_by`, policy rộng | `POST /api/v1/orders/outbound`; cùng prerequisite draft/idempotency. Hai đường tạo phiếu trùng. |
| Cùng file dòng 73 `confirmOutbound` | RPC `confirm_outbound_order` dòng 75 | Đổi phiếu và trừ tồn trong DB; EXECUTE đã grant rộng theo snapshot | `POST /api/v1/orders/{id}/confirm-outbound`; **phải** thay thế RPC bằng một transaction NestJS có status guard, idempotency, ledger; không cùng chạy. |
| `lib/features/ai_assistant/data/datasources/ai_remote_datasource.dart:52` `createDraftOrder` | Edge Function `createDraftOrderFunction` dòng 56 | Tên hàm gợi ý tạo phiếu; chưa có function body/deployment xác minh, side effect **chưa rõ** | Audit Edge Function trước cutover; nếu có DB write, đưa vào cùng đường command/idempotency. Không bật hai producer cùng lúc. |

`auth.signInWithPassword`/`signOut` thay đổi phiên Auth, không ghi bảng nghiệp vụ; giữ SDK Auth theo thiết kế hiện tại. `parseIntent` và `queryStock` Edge Functions có thể có side effect không nhìn thấy từ Flutter; cần audit implementation trước khi coi là read-only. `inventory_remote_datasource.dart` và `reports_remote_datasource.dart` chỉ SELECT/realtime trong source; không tìm thấy direct inventory INSERT/UPDATE/DELETE. Không có `.delete`/`.upsert` Supabase trong `lib/**/*.dart`. `orders` workspace review hiện dùng `PendingOrderWorkflowRepository` (trả lỗi không khả dụng) hoặc preview in-memory; không có production approval write path. `WarehouseOrderModel` có `approved_by` nullable, nhưng Flutter chưa ghi cột này vào Cloud.

## 5. RPC security findings

Snapshot schema-only DB-04C-03B (không phải kiểm chứng Cloud live ở B5) cho thấy `public.confirm_outbound_order(uuid)` là security invoker, EXECUTE grant cho `anon`/`authenticated`/`service_role`, không kiểm `auth.uid()`, ownership hoặc role trong body. Hàm UPDATE status COMPLETED cho phiếu OUTBOUND mà không đòi status trước đó; mỗi lần gọi lặp có thể trừ tiếp. Vòng lặp trừ theo `product_id` và vị trí; `location_id IS NULL` có thể khớp nhiều dòng. Dùng `GREATEST(0, quantity_on_hand - actual_quantity)` nên thiếu hàng bị che thành 0; không có ledger/idempotency. Không có `FOR UPDATE` tường minh; PostgreSQL UPDATE tự khóa row phù hợp nhưng không giải quyết repeat/business event. Quyền thực thi thực tế vẫn phụ thuộc ACL/RLS của caller. Cần xác minh function body/grants live trước release; **không sửa RPC trong B5**.

## 6. Cutover sequence

1. Owner duyệt role provenance, harden sáu policy/grants, kiểm RPC và Edge Functions, backup/restore assurance; triển khai migration/privileges trong task Cloud write riêng. Trước đó không kích hoạt adapter B4.
2. Kiểm tra PostgreSQL 17 integration: FK/RLS/backend DB role, idempotency concurrent, order state, rollback, ledger append và JWT theo cấu hình Supabase thật. Hoàn thiện các use case order/reservation còn thiếu.
3. Triển khai NestJS endpoint đã bảo vệ: Bearer → verify token/session theo policy → authorization/ownership → idempotency claim → transaction order/inventory → ledger append → response nhỏ → Flutter cập nhật UI từ response.
4. Chuyển một workflow một lần; smoke dữ liệu demo và Flutter DTO. Tắt đường direct write/RPC tương ứng **cùng đợt** với bật endpoint. Không phát song song lệnh trừ tồn từ RPC và NestJS; giữ read paths có kiểm quyền trong thời gian chuyển.
5. Theo dõi order status, số lượng tồn, ledger và idempotency; nếu sai, dừng traffic ghi và dùng forward-fix đã duyệt, không chạy rollback schema tùy tiện.

## 7. Test results và giới hạn

| Gate | Kết quả |
| --- | --- |
| `npm run prisma:validate`, `npm run prisma:generate` | PASS/PASS; chỉ kiểm tra offline |
| `npm run lint`, `npm run build` | PASS |
| `npm run test` | PASS, 64/64; ES256 local test keys và Auth mock, guard/RBAC |
| `npm run test:e2e` | PASS, 5/5; mock-only |
| `git diff --check` | PASS |

JWT tests bao phủ missing/malformed Bearer, wrong signature, expiration, issuer, audience, non-user role, forged user metadata, default fail-closed, ADMIN/MANAGER/STAFF và legacy Auth network/401/user mismatch. Không test Cloud JWKS rotation, Auth real-time revocation, network latency/rate limits, PostgreSQL integration, Flutter cutover hoặc Cloud migrations. Không thể tuyên bố SQL integration hoặc release READY.

## 8. Remaining release blockers và Git

Cloud chưa có `stock_ledger`, `idempotency_keys`, `approved_by` theo preflight Owner trước đây; migration, role/grants và live drift chưa kiểm chứng ở B5. Backup CUSTOM đọc được nhưng chưa restore thử. `profiles.role` và sáu RLS policies hiện hữu còn rộng; nguồn `app_metadata.wms_role` chưa được Owner provision/kiểm soát, JWKS signing mode thực tế chưa xác minh. RPC outbound có nguy cơ subtract lặp/thiếu ledger; inbound confirm chỉ đổi trạng thái. Adapter B4 và auth guards chưa wire; không có production inventory endpoint. **No-Go Cloud release/cutover** cho đến khi các gate này được duyệt và kiểm chứng.

Chỉ commit/push files B5 lên `feature/backend-nestjs-init` bằng Conventional Commit. Giữ nguyên untracked Owner SQL/tài liệu; không stage dump, backup, credentials. Hash commit và push status ghi trong phản hồi cuối sau khi thực hiện.
