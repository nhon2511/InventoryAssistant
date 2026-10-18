# Bàn giao contract frontend → backend Smart WMS

Cập nhật: 13/10/2026. Đây là yêu cầu adapter/contract, không phải API đã triển khai hoặc schema đề xuất đã được duyệt.

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
2. Cập nhật hồ sơ cá nhân và lưu tùy chọn giao diện: hồ sơ hiện chỉ đọc; theme được đổi trong phiên.
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
- OCR hiện chỉ parser văn bản dán có nhãn mô phỏng; chưa có pipeline ảnh/camera ML Kit.

## Nghiệm thu FE

Xem `docs/frontend-acceptance.md` và kết quả kiểm tra cuối trong kế hoạch. Chỉ đánh dấu user story hoàn thành khi cả UI, nghiệp vụ, BE và kiểm chứng thiết bị liên quan đạt tiêu chí.

## Ghi chú bàn giao sau chốt ba màn đại diện — 13/10/2026

- Bảng phiếu dùng đúng `WarehouseOrder.orderCode`, `createdAt`, `status`, `note`, `id`. Không có dữ liệu nhà cung cấp/người giao/tổng giá trị đáng tin cậy nên không thêm cột.
- Số kết quả và lọc hiện tính trên danh sách đã nhận. Chưa có contract cursor/page/total/search/status phía server, không dựng phân trang giả.
- Form không tạo contract mới: giữ `saveDraft` với nhiều items và requestId. UI luôn chờ kết quả typed; lỗi giữ draft, không báo thành công. Production adapter vẫn đang chờ triển khai, thông báo giao diện dùng ngôn ngữ người vận hành.
- Dashboard chỉ dùng snapshot tồn, danh mục đơn vị và header trạng thái; chưa có contract biến động/lịch sử nên không vẽ xu hướng hoặc tăng trưởng.
- Xác nhận rời form bảo vệ navigation trong ứng dụng; lưu draft qua reload/đóng tab chưa có contract persistence.
- Preview entry point chỉ thêm fixture/overrides; ba màn, router và logic giao diện là cùng một mã với production.
