# Kế Hoạch Thực Hiện Tiếp Theo - Smart WMS (InventoryAssistant)

> **Ngày cập nhật:** 10/10/2026  
> **Dự án:** Smart WMS - Hệ thống Quản lý Tồn kho Thông minh  
> **Công nghệ:** Flutter, Riverpod (Code Generation), Supabase, GoRouter, fpdart, Freezed, ML Kit, Speech-to-Text, FL Chart, Excel, PDF.

---

## 1. Tổng Quan Hiện Trạng Dự Án

### 1.1. Ưu điểm hiện tại (Current Strengths)
- **Kiến trúc ứng dụng chuẩn mực:** Áp dụng Clean Architecture (`presentation` -> `domain` <- `data`) phối hợp Riverpod code gen và `fpdart` (`Either<Failure, T>`).
- **Bộ dữ liệu & Đơn vị nghiệp vụ cơ bản:** Các mô hình chính (`Profile`, `Product`, `Location`, `InventoryItem`, `WarehouseOrder`, `PickListItem`, `ChatMessage`) đã hoàn chỉnh.
- **Bộ Test hiện có:** 28 test cases đã chạy PASS 100% trong `test/core` và `test/features`.
- **Tài liệu dự án chỉn chu:** `PRD_Smart_WMS.md`, `docs/system-architecture.md`, `docs/code-standards.md`, `docs/USER_STORIES.md`, `AGENTS.md` được đồng bộ.

### 1.2. Khoảng trống cần hoàn thiện (Gap Analysis)
1. **Chất lượng mã nguồn (Code Cleanliness & Analysis):**
   - Còn **17 thông báo lint (info level)** khi chạy `flutter analyze` (thứ tự constructor trong model Freezed, `eol_at_end_of_file`, sắp xếp dependencies `pubspec.yaml`).
2. **AI Assistant & Nhập lệnh bằng Giọng nói (US-13, US-14):**
   - Thư viện `speech_to_text` đã khai báo trong `pubspec.yaml`, cần hoàn thiện tích hợp micro/voice input trực tiếp vào `AiChatScreen`.
   - Cần hoàn thiện luồng **Human-in-the-loop Preview Draft Sheet** (xem trước bản nháp phiếu nhập/xuất do AI tạo trước khi xác nhận lưu DB).
3. **Dashboard, Quản lý vị trí & Báo cáo Nhập-Xuất-Tồn (US-15, US-16, US-17):**
   - Chưa tích hợp đầy đủ màn hình Báo cáo kho kết xuất tập tin **Excel** (`excel`) và **PDF** (`pdf`) cũng như biểu đồ thống kê tồn kho (`fl_chart`).
   - Giao diện Quản lý vị trí lưu trữ (Zone/Rack/Bin) cần bổ sung tính năng quản lý chi tiết.
4. **Độ bao phủ Kiểm thử (Test Coverage):**
   - Cần bổ sung test cho Controllers (`ProductController`, `OutboundController`, `AiChatController`), Repositories và Widget Tests.

---

## 2. Mục Tiêu & Tiêu Chí Hoàn Thành (Definition of Done)

- [ ] **100% Clean Code:** `flutter analyze` báo **0 issues**.
- [ ] **100% Test Passing:** Toàn bộ Unit & Widget Tests chạy xanh (`flutter test`).
- [ ] **Hoàn thiện 17/17 User Stories:** Bao gồm Voice AI Assistant, Preview Draft Sheet, Realtime Dashboard, Báo cáo Excel/PDF.
- [ ] **Đóng gói sản phẩm:** Build thành công APK Android & Deploy Web Admin.



---

## 3. Kế Hoạch Chi Tiết Theo Giai Đoạn (Roadmap & Action Plan)

```text
┌─────────────────────────────────────────────────────────────────────────┐
│ Phase 1: Chuẩn hóa Mã Nguồn & Fix Lint Warnings                         │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
┌────────────────────────────────────▼────────────────────────────────────┐
│ Phase 2: Hoàn Thiện Voice AI Assistant & Preview Draft Sheet            │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
┌────────────────────────────────────▼────────────────────────────────────┐
│ Phase 3: Phát Triển Module Báo Cáo (Excel/PDF) & Quản Lý Vị Trí Warehouse│
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
┌────────────────────────────────────▼────────────────────────────────────┐
│ Phase 4: Mở Rộng Bộ Test Suite (Controller, Repository & Widget Tests)  │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
┌────────────────────────────────────▼────────────────────────────────────┐
│ Phase 5: Tối Ưu Hiệu Năng & Đóng Gói Release / Báo Cáo Đồ Án            │
└─────────────────────────────────────────────────────────────────────────┘
```

### 🔹 Giai đoạn 1: Chuẩn hóa Mã Nguồn & Fix Lint Warnings (Thời gian: 0.5 - 1 ngày)
* **Mục tiêu:** Đảm bảo toàn bộ codebase tuân thủ `code-standards.md` và `very_good_analysis`.
* **Công việc cụ thể:**
  1. Cấu hình & sắp xếp lại dependencies trong `pubspec.yaml` theo thứ tự Alphabet.
  2. Định vị và sửa vị trí Unnamed Constructor trong các file models (`profile_model.dart`, `warehouse_order_model.dart`, `inventory_item_model.dart`, `location_model.dart`, `product_model.dart`, `pick_list_item_model.dart`).
  3. Xóa các dòng trống dư thừa ở cuối file (`eol_at_end_of_file`).
  4. Chạy `dart run build_runner build --delete-conflicting-outputs`.
  5. Kiểm tra lại bằng lệnh `flutter analyze` (yêu cầu ra kết quả 0 issue).

---

### 🔹 Giai đoạn 2: Nâng Cấp AI Assistant & Tích Hợp Voice Input (Thời gian: 2 ngày)
* **Mục tiêu:** Đáp ứng đầy đủ **US-13** (Tạo phiếu bằng AI) & **US-14** (Nhập lệnh bằng giọng nói).
* **Công việc cụ thể:**
  1. **Voice Input Service:** Tích hợp `speech_to_text` vào `AiChatScreen`, hỗ trợ nút bấm/giữ nói để chuyển giọng nói tiếng Việt thành văn bản.
  2. **Intent Parsing & Stock Query:** Hoàn thiện `ParseIntentUseCase` và `QueryStockUseCase` xử lý các intent: `query_stock`, `create_inbound_draft`, `create_outbound_draft`.
  3. **Human-in-the-loop Preview Draft Sheet:**
     - Thiết kế Bottom Sheet/Modal Preview hiển thị thông tin phiếu nháp do AI trích xuất (Tên hàng, SKU, Số lượng, Vị trí).
     - Cho phép thủ kho kiểm tra và chỉnh sửa trước khi xác nhận lưu DB.

---

### 🔹 Giai đoạn 3: Module Báo Cáo (Excel/PDF) & Quản Lý Vị Trí Kho (Thời gian: 2 - 3 ngày)
* **Mục tiêu:** Đáp ứng **US-16** (Quản lý vị trí kho) & **US-17** (Xem & xuất báo cáo nhập/xuất/tồn).
* **Công việc cụ thể:**
  1. **Quản lý Vị trí Lưu trữ (Location Management - US-16):**
     - Nâng cấp `location_list_screen.dart`: Cho phép thêm/sửa/xóa vị trí kho (Zone, Rack, Bin, Capacity).
     - Gắn liên kết trực tiếp giữa Sản phẩm và Vị trí trên sơ đồ kho.
  2. **Màn hình Báo cáo Nhập - Xuất - Tồn (Reports - US-17):**
     - Xây dựng màn hình `reports_screen.dart` sử dụng `fl_chart` hiển thị biểu đồ biến động tồn kho.
     - **Xuất Báo Cáo Excel:** Tích hợp package `excel` xuất dữ liệu danh sách tồn kho, lịch sử nhập/xuất ra file `.xlsx`.
     - **Xuất Báo Cáo PDF:** Tích hợp package `pdf` & `printing` tạo phiếu nhập/xuất và báo cáo tổng hợp dạng PDF để in.

---

### 🔹 Giai đoạn 4: Mở Rộng Bộ Test Suite (Thời gian: 1.5 - 2 ngày)
* **Mục tiêu:** Đảm bảo độ ổn định cao cho ứng dụng trước khi release.
* **Công việc cụ thể:**
  1. **Unit Tests cho Controllers:** Viết test cho `ProductController`, `InboundController`, `OutboundController`, `AiChatController` (kiểm tra các trạng thái Loading, Success, Error).
  2. **Unit Tests cho Repositories:** Test lớp Repository Impl kết hợp với Mock Datasources.
  3. **Widget Tests:** Viết widget test cho các luồng chính: `SignInScreen`, `ProductListScreen`, `InboundListScreen`, `PickVerifyScreen`.

---

### 🔹 Giai đoạn 5: Tối Ưu, Đóng Gói & Hoàn Thiện Tài Liệu (Thời gian: 1 ngày)
* **Mục tiêu:** Sẵn sàng cho Demo, Đánh giá Hội đồng & Nghiệm thu.
* **Công việc cụ thể:**
  1. Thử nghiệm toàn bộ luồng nghiệp vụ trên thiết bị thật (Android APK / iOS / Web).
  2. Chạy lại toàn bộ kiểm tra chất lượng:
     ```bash
     flutter analyze
     flutter test
     ```
  3. Cập nhật `README.md` với đầy đủ hướng dẫn cài đặt, cấu hình `.env` và ảnh chụp màn hình demo.
  4. Đóng gói ứng dụng (Android APK release build) và chuẩn bị Slide thuyết trình đồ án (Thesis Presentation).

---

## 4. Tóm Tắt Nhiệm Vụ Cần Làm Ngay (Next Immediate Tasks)

1. **Task 1:** Fix 17 lint warnings trong `lib/features/**/models/*.dart` & `pubspec.yaml`.
2. **Task 2:** Kết nối `speech_to_text` vào `AiChatScreen` và hoàn thiện giao diện Draft Preview Sheet cho AI.
3. **Task 3:** Tạo `ReportsScreen` với tính năng Xuất Excel (`excel`) & PDF (`pdf`).
4. **Task 4:** Thêm Unit Tests cho Controllers & Repositories.
