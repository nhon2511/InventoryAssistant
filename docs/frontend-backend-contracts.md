# Bàn giao contract frontend → backend Smart WMS

Cập nhật: 13/10/2026. Đây là yêu cầu adapter/contract, không phải API đã triển khai hoặc schema đề xuất đã được duyệt.

## CP3 — Adapter danh mục Flutter → NestJS (27/11/2026)

Production providers hiện dùng `NestApiClient` với Supabase access token cho `GET/POST/PUT/DELETE /api/v1/products` và `/api/v1/locations`. List, detail và tìm barcode đọc cùng nguồn NestJS với thao tác ghi; tìm tên/SKU và lọc vị trí trên danh sách đã tải. Mã mới dùng POST không gửi ID, sửa dùng PUT với ID server trả về. ADMIN/MANAGER được tạo/sửa; chỉ ADMIN được xóa; STAFF chỉ xem. Backend guard vẫn là nơi quyết định quyền cuối cùng. Stock theo sản phẩm trên màn chi tiết dùng `GET /api/v1/inventory/stock?productId=...`; báo cáo và các nguồn đọc ngoài danh mục không nằm trong cutover này.

Client chấp nhận envelope thành công từ interceptor (200/201) và 204 khi xóa; lỗi từ exception filter được ánh xạ theo status, gồm 409 duplicate SKU/barcode hoặc còn tham chiếu. UI giữ form khi lưu lỗi. Preview tiếp tục dùng repository fixture riêng. Build/test với mock không xác minh endpoint, role claim, schema hoặc dữ liệu thật trên Supabase; URL NestJS vẫn cần cấu hình theo môi trường như README.

## CP1 — Kiểm kê contract Android + Web (27/11/2026)

Đây là đối chiếu tĩnh mã nguồn Flutter/NestJS và năm migration local. Không chạy app/test, không kết nối Supabase và không xác minh API/database thật. “Có trong mã” không đồng nghĩa đã tích hợp hoặc được phép cutover. Flutter production entry là `lib/main.dart`; preview dùng dependency fixture riêng.

| US / chức năng | Flutter: màn, controller, repository | Datasource hiện tại | NestJS API tương ứng (mã nguồn) | Supabase bảng/trường liên quan | Quyền | Trạng thái CP1 |
|---|---|---|---|---|---|---|
| US-01 Đăng nhập | Login/Register/Profile; `AuthController`; `AuthRepositoryImpl` | Supabase Auth `signInWithPassword`, `signUp`, `signOut`; đọc/insert `profiles` | Không có auth API cho app; guard xác minh access token Supabase qua JWKS | `auth.users`; `profiles.id`, `full_name`, `role`, `phone_number` | Đăng nhập cần tài khoản; đăng ký đặt mặc định STAFF ở client; quyền dữ liệu thật còn do RLS/server | Có code; session/profile và email-confirm chưa xác minh thật |
| US-02 Phân quyền | `AuthController`; role checks ở màn sản phẩm/vị trí/phiếu | Profile role Supabase; guard UI | `JwtAuthenticationGuard` + `TrustedRolesGuard`; role đọc từ `app_metadata.wms_role` khi cấu hình bật trust | claim `sub`, `role`, `app_metadata.wms_role`; `profiles.role` không được backend guard tra cứu trong request này | Products/locations read: token; CRUD create/update ADMIN/MANAGER, delete ADMIN; inventory/order read/write roles theo endpoint; review/confirm ADMIN/MANAGER | Backend guard có mã; cấu hình role provisioning và khớp `profiles.role` với JWT chưa xác minh |
| US-03 Quét barcode/QR hàng loạt | `BatchScanScreen`, `BatchScannerController`; thêm mã vào `OrderFormScreen` | Camera/device `MobileScanner`; tồn từ danh sách sản phẩm đã nạp | Không có API scan | Đọc `products.id`, `barcode`; dòng draft dự kiến `warehouse_order_items` | Người dùng đăng nhập; chưa có kiểm tra quyền server riêng cho scan | UI/session; chưa chứng minh camera thật trên Android/Web hoặc ghi backend |
| US-04 OCR lô/HSD | `OcrScanScreen`, `ImageOcrService` | OCR chạy browser Tesseract cho Web; parser local | Không có API OCR | Chưa ghi bảng; giá trị nếu nhập vào form là `lot_number`, `expiry_date` ở order item | Không có quyền server ở bước OCR | Web code có; Android/thiết bị thật và độ chính xác chưa xác minh; chưa ghi tồn |
| US-05 Tạo/duyệt phiếu nhập | `OrderFormScreen`, `OrderWorkspaceController`, `OrderWorkflowRepository` pending; legacy `InboundRepositoryImpl` | Workspace mới: Pending, không gọi mạng. Legacy: insert header và từng line qua Supabase; `confirmInbound` update status | `POST /api/v1/orders/draft`; `POST /api/v1/orders/:id/review`; `POST /api/v1/orders/:orderId/confirm` | `warehouse_orders`: `order_code,type,status,created_by,approved_by,note`; `warehouse_order_items`: `order_id,product_id,location_id,expected_quantity,actual_quantity,lot_number,expiry_date`; xác nhận dùng `inventory_items` và `stock_ledger` | Draft ADMIN/MANAGER/STAFF; review/confirm ADMIN/MANAGER | Draft API transaction có code nhưng chưa wired vào Flutter; legacy confirm nhập chỉ đổi `status=COMPLETED`, không tăng tồn. Nest confirm cập nhật tồn+ledger trong code nhưng cần schema đúng và kiểm chứng DB |
| US-06 Tra cứu tồn | Product list/detail; stock overview; `ProductController`, `InventoryWorkspaceController`; `InventoryRepositoryImpl` | Supabase `products`, `inventory_items` | `GET /api/v1/products`, `GET /api/v1/products/:id`, `GET /api/v1/inventory/stock` | `products`: `id,sku,barcode,name,unit,min_safety_stock`; `inventory_items`: `product_id,location_id,quantity_on_hand,quantity_reserved,lot_number,expiry_date` | Supabase RLS hiện hành chưa xác minh; Nest read cần JWT, inventory cần ADMIN/MANAGER/STAFF | Direct Supabase reads có callsite; Nest read code có nhưng chưa được Flutter gọi/live verify |
| US-07 Theo dõi vị trí | Location list, stock/product detail; `LocationController`, `InventoryWorkspaceController` | Supabase `locations`, `inventory_items` | `GET /api/v1/locations`, `GET /api/v1/locations/:id`, `GET /api/v1/inventory/stock` | `locations`: `id,zone_code,aisle_code,rack_code,bin_code,location_barcode,max_capacity_kg`; inventory `location_id` | Token; RLS chưa xác minh | Đọc có code; Nest read có code; dữ liệu thật/chính sách chưa kiểm chứng |
| US-08 Cảnh báo tồn thấp | `StockOverviewScreen`; controller tồn và product | Supabase snapshot sản phẩm+tồn | Chưa có low-stock aggregate endpoint; `GET /inventory/stock` trả danh sách tồn | `products.min_safety_stock`; `inventory_items.quantity_on_hand`, `quantity_reserved` | Read role theo nguồn | UI tính từ snapshot; ngưỡng/aggregate/server consistency chưa xác minh |
| US-09 Pick list | Order list/detail, outbound; `OrderWorkspaceController` đọc phiếu | Legacy Supabase đọc header; outbound datasource chưa tải line items | `GET /api/v1/orders?type=OUTBOUND`, `GET /api/v1/orders/:id` trả items | `warehouse_orders`; `warehouse_order_items`; product/location fields | Nest cần JWT + role ADMIN/MANAGER/STAFF; ownership filtering không tự áp dụng nếu thiếu query | Nest detail có line items; Flutter chưa dùng API; legacy detail thiếu line items |
| US-10 Quét đối soát xuất | `PickVerifyScreen`, `PickVerifyController` | Barcode/device và state đếm theo phiên | Chưa có API ghi từng lần scan/line actual | Đọc `products.barcode`, `warehouse_order_items.expected_quantity`; actual/session chưa được lưu bởi FE | UI không thay server authorization/stock validation | Chỉ phiên/UI; chưa có persistent scan API |
| US-11 Xác nhận xuất, trừ tồn | Outbound list/detail; `OutboundRepositoryImpl` legacy và shared workspace Pending | Legacy `confirmOutbound` gọi RPC `confirm_outbound_order`; workspace mới chưa gọi API | `POST /api/v1/orders/:orderId/confirm` (transaction + idempotency theo code); `POST /api/v1/inventory/ship` là đường xuất trực tiếp khác | order/items, `inventory_items.quantity_on_hand/quantity_reserved`, `stock_ledger`, `idempotency_keys` | RPC/RLS chưa xác minh; Nest order confirm ADMIN/MANAGER; direct inventory ship ADMIN/MANAGER/STAFF | Không được gọi RPC và Nest confirm cho cùng order. RPC implementation/ledger chưa được review vì không có SQL function trong repo; Nest confirm có implementation nhưng migration local không tương thích hiện tại |
| US-12 Hỏi tồn bằng AI | `AiChatController`; `AiAssistantRepositoryImpl` | Supabase Edge Functions `parse-intent`, `query-stock` | Không có Nest AI API | Có thể truy vấn products/inventory qua Edge Function; query cụ thể không có trong repo | Auth/RLS/role của Edge Functions chưa xác minh | Có callsite; function/deploy/thực thi thật chưa xác minh; preview mô phỏng |
| US-13 Tạo phiếu bằng AI | `AiChatController`, `CreateDraftOrderUseCase` | Edge Function `create-draft-order`; preview dùng fixture | Sau xác nhận người dùng, API draft dự kiến `POST /orders/draft`; hiện không được gọi từ luồng AI | Nếu Edge Function ghi: `warehouse_orders`, `warehouse_order_items`; cần xác minh triển khai | Token/ownership và quyền tạo draft phải do server kiểm tra | Có callsite Edge Function nhưng chưa xác minh function; không coi draft Nest đã tích hợp; không cho AI xác nhận tồn |
| US-14 Nhập lệnh giọng nói | AI chat + `SpeechService` | Nhận dạng giọng nói trên thiết bị thành text, sau đó mới gửi intent | Không có speech endpoint | Chưa có thay đổi DB riêng | Cấp quyền microphone tại thiết bị; request AI theo auth | UI/device capability; chưa xác minh mic/tiếng Việt thật |
| US-15 Realtime tồn | `InventoryRealtimeController` / `InventoryRepositoryImpl` | Supabase Realtime stream `inventory_items` | Không có Nest websocket; Nest mutation kỳ vọng phát thay đổi PostgreSQL | `inventory_items` (các trường tồn và `updated_at`) | RLS/Realtimes publication/quyền subscriber chưa xác minh | Có subscription code; chưa kiểm chứng event thật, snapshot consistency hoặc cleanup trên backend thật |
| US-16 Quản lý vị trí | `LocationListScreen`, `InventoryEditDialog`; maintenance repository Pending | Đọc Supabase; ghi workspace trả Pending | `POST/PUT/DELETE /api/v1/locations` | `locations` fields nêu ở US-07, cùng references `inventory_items`/`warehouse_order_items` | Create/update ADMIN/MANAGER; delete ADMIN; server chặn references theo service | API/service CRUD có code; FE production adapter pending; chưa live verify |
| US-17 Báo cáo nhập/xuất/tồn | `ReportsScreen`, `ReportsController` | Đọc products, inventory_items, locations; lọc header phiếu theo client | Chưa có report aggregate endpoint; có `GET /inventory/stock` và `GET /orders` | Product/location/inventory snapshot và `warehouse_orders.created_at,type,status`; không có ledger đang được đọc | Supabase RLS chưa xác minh; Nest JWT/role theo route | Snapshot + lịch sử header; không phải ledger theo kỳ; chưa gọi Nest/live verify |

### Kết luận CP1 về đường dữ liệu

- Supabase Auth tiếp tục cấp session/access token. Flutter cần gửi access token đó dưới `Authorization: Bearer` tới NestJS; hiện repository Flutter chưa có HTTP client/adapter NestJS.
- Sau khi chốt role claim provisioning và schema compatibility, dùng NestJS làm **đường ghi nghiệp vụ duy nhất**: tạo draft nguyên tử, review, xác nhận nhập/xuất. Không vừa gọi `confirm_outbound_order` vừa gọi Nest confirm. Legacy `confirmInbound` tuyệt đối không dùng làm hoàn tất nhập vì chỉ cập nhật trạng thái.
- Không dùng `POST /inventory/receive` hoặc `/inventory/ship` cho workflow có order: hai API này mutate trực tiếp inventory mà không dùng idempotency/ledger trong service hiện tại, có thể tạo tồn lệch khỏi phiếu. Chỉ cân nhắc sau khi định nghĩa rõ nghiệp vụ adjustment và audit.
- Giữ Supabase cho Auth, các truy vấn read hiện tại trong giai đoạn adapter chưa thay, và Realtime `inventory_items`. Dài hạn có thể chuyển product/location/inventory reads và order queries sang NestJS sau khi response/paging/ownership/RLS được thống nhất. Edge Functions AI giữ riêng tới khi implementation và quyền được xác minh; AI chỉ tạo draft, không xác nhận stock.
- Nest `GET /orders` chấp nhận filter `createdBy` nhưng service không tự scope STAFF theo actor; `GET /orders/:id` cũng chưa enforce ownership. Cần server scope/authorization rõ ràng trước khi chuyển list/detail sang API.

### Rà soát tĩnh các migration local — không áp dụng

Năm file dưới `supabase/migrations/` còn untracked và được giữ nguyên; header của chúng ghi `STATIC_REVIEW_ONLY`/`NOT_EXECUTED`. Điều này chỉ là trạng thái ghi trong file, không xác minh trạng thái Supabase Cloud. Có blocker tương thích code hiện tại:

- `20261113000001_create_stock_ledger.sql` không có `inventory_item_id`, trong khi Prisma và adapter Nest yêu cầu trường/FK này; `created_by` FK tới `profiles`, còn Prisma comment/code coi đây là actor snapshot không FK. Candidate cũng thiếu các index/FK khớp schema hiện tại.
- `20261113000002_create_idempotency_keys.sql` dùng `user_id` và `PRIMARY KEY(key)`, trong khi Prisma/adapter dùng `scope_id` và khóa `(scope_id,key)`. Không thể áp dụng nguyên trạng rồi kỳ vọng endpoint confirm chạy.
- `20261113000003` thêm `approved_by` nhưng FK tới `profiles`; cần đối chiếu hợp đồng actor/schema trước khi dùng.
- `20261113000004` thêm CHECK constraint trực tiếp (không `NOT VALID`) và có thể fail nếu dữ liệu hiện hữu vi phạm; không có preflight nào được chạy ở CP1.
- `20261113000005` policy tham chiếu `idempotency_keys.user_id`, không khớp model `scope_id`; ledger policy cho phép authenticated đọc mọi row (`USING(true)`), và append-only enforcement chỉ là comment tùy chọn.

Chưa có bằng chứng CP1 rằng các migration đã apply, test tích hợp DB đã chạy, hay Nest endpoint đã phục vụ traffic thật. Cần một nguồn schema canonical, migration mới được owner duyệt, audit RPC hiện hữu và kiểm chứng ở test DB cô lập trước cutover.

## Phạm vi và nguyên tắc

- Giữ các repository Supabase hiện có, Flutter, Riverpod, GoRouter và Clean Architecture.
- Entry point thật: `lib/main.dart`. Entry point xem trước: `lib/main_preview.dart`; overrides chỉ tại composition root, dữ liệu fixture trong bộ nhớ và AI mô phỏng có nhãn rõ.
- Không đổi schema, RPC, Edge Function, cấu hình Supabase hoặc dependency version trong đợt FE.
- Guard và lọc theo người tạo ở FE không thay RLS, authorization hoặc kiểm tra tồn ở server.
- Không dùng `confirmInboundOrder` hiện có để chứng minh tăng tồn: datasource hiện chỉ đổi trạng thái thành COMPLETED.
- Không suy ra tồn đầu/cuối kỳ hoặc số lượng thực nhập/xuất từ trạng thái phiếu.

## Contract đã có và được FE sử dụng

| Contract | FE dùng cho | Tích hợp còn cần xác minh |
|---|---|---|
| AuthRepository signIn/signUp/getCurrentProfile/signOut | Đăng nhập, đăng ký, hồ sơ, vai trò | Email confirmation, session expiry, ánh xạ lỗi và dữ liệu profile thật |
| InventoryRepository getAllProducts/getProductById/getProductByBarcode | Danh sách/tìm/chi tiết/tra mã | RLS, dữ liệu thật, mã duy nhất |
| getAllLocations/getStockByProduct/getAllInventoryItems/subscribeInventoryRealtime | Vị trí, tồn theo SKU, dashboard, báo cáo | Realtime, cleanup, tính nhất quán snapshot, trường tên/đơn vị/vị trí |
| InboundRepository getInboundOrders/getInboundOrderById | Danh sách, chi tiết nhập và line items | Scope người tạo do server kiểm tra |
| OutboundRepository getOutboundOrders/getOutboundOrderById | Danh sách và header phiếu xuất | Adapter hiện chưa tải line items; không được coi danh sách rỗng là đã đối soát |
| AiAssistantRepository parseIntent/queryStock | Chat và truy vấn tồn | Chưa gọi/xác minh Edge Function thật trong đợt này |

## Capability FE mới, production adapter chưa có

### InventoryMaintenanceRepository

File: `lib/features/inventory/domain/repositories/inventory_maintenance_repository.dart`.

- `saveProduct(Product)`: upsert theo id; name, SKU, barcode, unit bắt buộc, minSafetyStock là số nguyên không âm. Server kiểm tra role ADMIN, unique SKU/barcode, validation; trả entity canonical và timestamp.
- `deleteProduct(id)`: từ chối khi có tồn/tham chiếu phiếu; kiểm tra role trên server.
- `saveLocation(Location)`: zone/aisle/rack/bin/barcode bắt buộc, capacity tùy chọn nhưng hữu hạn và >0; unique cấu trúc vị trí/barcode.
- `deleteLocation(id)`: kiểm tra tồn và mọi tham chiếu.
- `available` phản ánh adapter đã được cấu hình; không phải bằng chứng tích hợp đã kiểm chứng.
- Production mặc định `PendingInventoryMaintenanceRepository`, trả Failure tiếng Việt và không gửi network write.

### OrderWorkflowRepository

File: `lib/features/orders/domain/repositories/order_workflow_repository.dart`.

- `saveDraft(type, createdBy, items, requestId, note)`: lưu nguyên tử header + tất cả line items; requestId idempotency; xác thực createdBy theo session, không tin giá trị client; trả đầy đủ entity/dòng hàng.
- Dòng hàng: id, productId, locationId, expectedQuantity >0; actualQuantity lúc nháp bằng 0, không suy ra đã nhận hàng.
- Server kiểm tra sản phẩm/vị trí tồn tại, số lượng, quyền, đơn vị, requestId và concurrency.
- FE cộng gộp dòng xuất trùng product/location, so với quantityOnHand − quantityReserved nếu có snapshot. Server phải kiểm tra lại với lock/transaction; FE không thay thế kiểm tra này.
- `review(orderId, expectedStatus, approve, reviewerId)`: compare-and-set trạng thái DRAFT → CONFIRMED hoặc CANCELLED; ADMIN/MANAGER; xác thực reviewer từ session; audit. Không hàm ý tồn đã thay đổi.
- Production `PendingOrderWorkflowRepository` không gọi API giả.
- Cần thỏa thuận trạng thái từ chối riêng nếu nghiệp vụ muốn phân biệt CANCELLED với REJECTED; FE hiện chỉ dùng enum sẵn có.

### Contract còn cần thỏa thuận trước tích hợp

1. Dữ liệu danh mục, warehouse và quan hệ với product/location: model hiện chưa có categoryId/warehouseId hoặc entity tương ứng. Không tự tạo schema trên FE.
2. Cập nhật hồ sơ cá nhân: hồ sơ hiện chỉ đọc. Theme được lưu cục bộ bằng SharedPreferences; không đồng bộ tùy chọn giữa thiết bị.
3. Hoàn tất nhập/xuất, reservation, kiểm kê, batch scan, đối soát: cần giao dịch tồn an toàn, kiểm tra trạng thái/quyền và retry idempotent. FE hiện không hiển thị thành công cập nhật tồn.
4. Kết quả đối soát barcode: dòng phiếu, product barcode, số lượng/session, location và lưu kết quả; hiện số đếm chỉ trong phiên.
5. Ledger lịch sử: timestamp giao dịch, type, product, location, unit, delta, balance, order/user reference và quyền phạm vi. Dùng ledger mới tính tồn đầu/cuối kỳ và biểu đồ biến động.
6. Phân trang, lọc phía server và ownership scope cho danh sách lớn; FE hiện tìm/lọc trên dữ liệu đã nhận.
7. NLU draft: single-line `Map<String,String>` hiện hỗ trợ product_id/sku/barcode/product_name, location_id/location_barcode/location, quantity, note; intent create_inbound_draft/create_outbound_draft hoặc create_order với type rõ. Không đoán sản phẩm/vị trí khi kết quả không duy nhất. Multi-line, lot, expiry và đơn vị cần contract typed mở rộng.
8. Đăng ký cần kiểm thử chế độ yêu cầu xác minh email; auth repository hiện trả Profile, chưa có state riêng cho chờ xác minh.

## Báo cáo và thiết bị

- Excel gồm tồn hiện tại, lịch sử header phiếu theo ngày tạo và sheet phạm vi. Không có số liệu trang trí.
- PDF dùng dữ liệu tương tự, font Unicode từ Printing tải ở lần đầu; offline lần đầu hoặc hạn chế tải/chia sẻ có thể thất bại và UI báo lỗi.
- Camera barcode dùng MobileScanner trên web/Android/iOS: cần HTTPS/localhost, permission và kiểm tra thiết bị. Chưa xác minh nhận mã từ camera thật.
- Voice dùng speech_to_text; văn bản nhận diện cần người dùng bấm gửi. Chưa xác minh micro/nhận tiếng Việt trên thiết bị thật.
- OCR ảnh web dùng Tesseract.js chạy trong trình duyệt, tải worker/WASM và dữ liệu `vie+eng` từ jsDelivr khi người dùng chọn ảnh. Không gửi ảnh lên Supabase/backend. FE phân tích LOT/HSD bằng parser hiện có và yêu cầu người dùng rà soát; chưa lưu phiếu hoặc thay đổi tồn.
- Chưa xác minh CDN/CSP, khả năng camera trên thiết bị thật hoặc độ chính xác OCR. Camera web yêu cầu HTTPS/localhost và quyền trình duyệt. ML Kit Flutter vẫn không dùng cho web; không coi kiểm thử widget giả là kiểm chứng nhận diện ngoài trình duyệt.

## Nghiệm thu FE

Xem `docs/frontend-acceptance.md` và kết quả kiểm tra cuối trong kế hoạch. Chỉ đánh dấu user story hoàn thành khi cả UI, nghiệp vụ, BE và kiểm chứng thiết bị liên quan đạt tiêu chí.

## Ghi chú bàn giao sau chốt ba màn đại diện — 13/10/2026

- Bảng phiếu dùng đúng `WarehouseOrder.orderCode`, `createdAt`, `status`, `note`, `id`. Không có dữ liệu nhà cung cấp/người giao/tổng giá trị đáng tin cậy nên không thêm cột.
- Số kết quả và lọc hiện tính trên danh sách đã nhận. Chưa có contract cursor/page/total/search/status phía server, không dựng phân trang giả.
- Form không tạo contract mới: giữ `saveDraft` với nhiều items và requestId. UI luôn chờ kết quả typed; lỗi giữ draft, không báo thành công. Production adapter vẫn đang chờ triển khai, thông báo giao diện dùng ngôn ngữ người vận hành.
- Dashboard chỉ dùng snapshot tồn, danh mục đơn vị và header trạng thái; chưa có contract biến động/lịch sử nên không vẽ xu hướng hoặc tăng trưởng.
- Xác nhận rời form bảo vệ navigation trong ứng dụng; lưu draft qua reload/đóng tab chưa có contract persistence.
- Preview entry point chỉ thêm fixture/overrides; ba màn, router và logic giao diện là cùng một mã với production.
