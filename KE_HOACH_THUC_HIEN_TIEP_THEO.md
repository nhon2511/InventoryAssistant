# Kế Hoạch Thực Hiện Tiếp Theo - Smart WMS (InventoryAssistant)

> **Ngày cập nhật:** 03/11/2026  
> **Dự án:** Smart WMS - Hệ thống Quản lý Tồn kho Thông minh  
> **Công nghệ:** Flutter, Riverpod (Code Generation), Supabase, GoRouter, fpdart, Freezed, ML Kit, Speech-to-Text, FL Chart, Excel, PDF, MobileScanner.

---

## 1. Tổng Quan Tiến Độ Hiện Trạng Dự Án (Cập nhật 03/11/2026)

### 1.1. Các Hạng Mục Đã Hoàn Thành (Completed Milestones) ✅
1. **Kiến trúc & Chuẩn hóa Mã Nguồn (Clean Architecture & Linting):**
   - Áp dụng chuẩn Clean Architecture (`presentation` -> `domain` <- `data`) phân tách rõ ràng.
   - Quản lý trạng thái bằng Riverpod code generation, xử lý lỗi an toàn kiểu dữ liệu với `fpdart` (`Either<Failure, T>`).
   - Sắp xếp dependencies, sửa lỗi constructor Freezed models, chuẩn hóa toàn bộ codebase.
2. **Xác thực & Phân quyền (Auth & RBAC — US-01, US-02):**
   - Đăng nhập, đăng ký, phiên làm việc người dùng kết nối Supabase Auth.
   - Phân quyền người dùng theo vai trò: `ADMIN`, `MANAGER`, `STAFF`.
   - Điều hướng GoRouter với Auth Guard tự động bảo vệ route.
3. **Quản lý Tồn kho & Đồng bộ Realtime (Inventory — US-06, US-07, US-08, US-15):**
   - Tra cứu sản phẩm, danh mục vị trí kệ kho.
   - Thống kê tồn kho tổng quan, cảnh báo mức tồn an toàn (*Safety Stock Alert*).
   - Lắng nghe sự kiện thay đổi dữ liệu realtime qua kênh Supabase Realtime channel.
4. **Phân hệ Trợ lý AI & Nhập Giọng nói (AI Assistant — US-12, US-13, US-14):**
   - Giao diện trò chuyện trực quan `AiChatScreen`.
   - Nhập lệnh giọng nói tiếng Việt bằng `SpeechService` (`speech_to_text`).
   - Trích xuất ý định (Intent Parsing) cho tra cứu tồn kho và tạo phiếu nháp.
   - Cơ chế kiểm soát an toàn **Human-in-the-loop Preview Draft Sheet** cho phép người dùng rà soát bản nháp phiếu trước khi lưu vào DB.
5. **Phân hệ Báo Cáo & Thống Kê (Reports — US-17):**
   - Màn hình `ReportsScreen` với các thẻ KPI tóm tắt.
   - Biểu đồ trực quan hóa dữ liệu tồn kho bằng `fl_chart`.
   - Xuất dữ liệu bảng tồn kho ra tập tin **Excel (`.xlsx`)** qua package `excel`.
   - Kết xuất báo cáo **PDF chuyên nghiệp (`.pdf`)** qua `pdf` + `printing` và chia sẻ tập tin qua `share_plus`.
6. **Cấu hình Quyền & Quét Đối Soát Xuất Kho (Sprint 1 - một phần):**
   - Khai báo đầy đủ quyền `CAMERA`, `RECORD_AUDIO`, `FLASHLIGHT` trong `AndroidManifest.xml` và `Info.plist`.
   - Xây dựng `PermissionService` quản lý trạng thái quyền và điều hướng đến App Settings khi bị chặn.
   - Hoàn thiện màn hình camera đối soát xuất kho `PickVerifyScreen` kết nối `MobileScanner`, `PickVerifyController`, tự động tăng số lượng khi đúng mã và hiển thị cảnh báo lỗi khi sai mã hoặc vượt số lượng.

---

### 1.2. Các Khoảng Trống Cần Hoàn Thiện Tiếp Theo (Remaining Gaps) ⏳
1. **Quét Barcode Hàng Loạt & Quét OCR Nhập kho (US-03, US-04):**
   - `BatchScanScreen`: Cần thay thế placeholder bằng widget `MobileScanner` quét liên tục nhiều mã và cộng dồn số lượng.
   - `OcrScanScreen`: Cần tích hợp `google_mlkit_text_recognition` kết nối `OcrTextExtractor` để bóc tách Số lô (LOT) và Hạn sử dụng (EXP).
2. **Giao diện Chi tiết Đơn hàng & Quản lý Vị trí kho (US-16):**
   - `InboundDetailScreen`: Hiển thị danh sách line items, trạng thái và nút xác nhận phiếu nhập.
   - `OutboundDetailScreen`: Hiển thị tiến độ pick list và shortcut chuyển sang máy quét đối soát.
   - `ProductDetailScreen`: Hiển thị chi tiết vị trí phân bổ hàng hóa theo từng kệ.
   - Quản lý vị trí (US-16): Thêm form CRUD tạo/sửa vị trí lưu trữ trên `LocationListScreen`.
3. **Độ Bao Phủ Kiểm Thử (Test Coverage):**
   - Mở rộng Unit Tests cho toàn bộ Riverpod Controllers (`InboundController`, `OutboundController`, `BatchScannerController`, `ReportsController`, `AiChatController`).
   - Bổ sung Widget Tests cho các màn hình then chốt.
4. **Đóng Gói & Nghiệm Thu Đồ Án:**
   - Thử nghiệm trên thiết bị di động thật (Android/iOS).
   - Build file cài đặt `flutter build apk --release`.

---

## 2. Đánh Giá Tỷ Lệ Tiến Độ (Progress Scorecard)

| Phân hệ / Tiêu chí | Trọng số | Tỷ lệ hoàn thành | Tình trạng |
| :--- | :---: | :---: | :--- |
| **Kiến trúc & Core Utils** | 10% | **95%** | Rất tốt, chuẩn Clean Architecture & fpdart |
| **Auth & Phân quyền (US-01, US-02)** | 10% | **95%** | Hoàn thành đăng nhập, đăng ký, RBAC |
| **Tồn kho & Realtime (US-06, 07, 08, 15)** | 15% | **85%** | Realtime stream, overview, cảnh báo an toàn |
| **Báo cáo & Xuất Excel/PDF (US-17)** | 15% | **95%** | Biểu đồ fl_chart, xuất file .xlsx và .pdf |
| **Trợ lý AI & Giọng nói (US-12, 13, 14)** | 15% | **85%** | Voice input, intent parsing, preview draft |
| **Nhập kho & Quét OCR (US-03, 04, 05)** | 15% | **65%** | Domain/Data xong; BatchScan & OcrScan UI đang TODO |
| **Xuất kho & Đối soát (US-09, 10, 11)** | 10% | **80%** | PickVerifyScreen đã xong; còn OutboundDetail |
| **Quản lý vị trí kho (US-16)** | 5% | **50%** | Mới có danh sách vị trí, chưa có CRUD UI |
| **Kiểm thử tự động (Unit & Widget Tests)** | 5% | **45%** | Mới có 7 file test domain/utils cơ bản |
| **TỔNG THỂ DỰ ÁN** | **100%** | **~80%** | **Tiến độ tốt, các phần lõi phức tạp nhất đã xong** |

---

## 3. Kế Hoạch Thực Hiện Trong Tương Lai (Next Action Plan)

```text
┌────────────────────────────────────────────────────────────────────────┐
│ Phase 1: Hoàn Thiện Camera Nhập Kho (Batch Barcode Scanner & ML Kit)  │ (1.5 ngày)
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│ Phase 2: Hoàn Thiện Các Màn Hình Chi Tiết & CRUD Vị Trí Kho (US-16)    │ (2 ngày)
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│ Phase 3: Mở Rộng Bộ Kiểm Thử (Unit Tests Controllers & Widget Tests)   │ (2 ngày)
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│ Phase 4: Thử Nghiệm Thiết Bị Thật, Build APK Release & Nghiệm Thu      │ (1.5 ngày)
└────────────────────────────────────────────────────────────────────────┘
```

### 🔹 Giai đoạn 1: Hoàn thiện Camera Nhập kho (MobileScanner & ML Kit OCR)
* **Thời gian:** 1.5 ngày  
* **Độ ưu tiên:** P0 (Cao nhất)
* **Công việc cụ thể:**
  1. **BatchScanScreen:**
     - Tích hợp `MobileScanner` vào `lib/features/inbound/presentation/widgets/batch_scan_screen.dart`.
     - Kết nối với `BatchScannerController.addBarcode()`, kích hoạt rung `HapticFeedback.lightImpact()` khi quét nhận diện.
     - Thiết kế thanh Bottom Sheet hiển thị số mã duy nhất, tổng lượt quét và danh sách mã cộng dồn số lượng.
     - Thêm nút "Tạo phiếu nhập từ danh sách" điều hướng sang luồng xác nhận nhập kho.
  2. **OcrScanScreen:**
     - Tích hợp `google_mlkit_text_recognition` vào `lib/features/inbound/presentation/widgets/ocr_scan_screen.dart`.
     - Chuyển ảnh quét qua `OcrTextExtractor.extractLotAndExpiry()` để bóc tách Số lô (LOT) và Hạn sử dụng (EXP).
     - Hiển thị Card chỉnh sửa dữ liệu nhận diện trước khi áp dụng vào phiếu nhập.

---

### 🔹 Giai đoạn 2: Hoàn thiện Màn hình Chi tiết & CRUD Vị trí kho (US-16)
* **Thời gian:** 2 ngày  
* **Độ ưu tiên:** P1
* **Công việc cụ thể:**
  1. **InboundDetailScreen:** Hiển thị thông tin phiếu nhập, danh sách từng dòng hàng, số lượng quét được và nút "Xác nhận nhập kho".
  2. **OutboundDetailScreen:** Hiển thị danh sách hàng cần nhặt, thanh tiến độ picking và nút shortcut mở `PickVerifyScreen`.
  3. **ProductDetailScreen:** Hiển thị thông số chi tiết sản phẩm, danh sách kệ đang lưu trữ và số lượng tồn trên từng kệ.
  4. **Quản lý Vị trí kho (US-16):** Bổ sung Dialog thêm/sửa vị trí kho trên `LocationListScreen` (Zone, Rack, Bin, Sức chứa kg).

---

### 🔹 Giai đoạn 3: Mở rộng Bộ Kiểm thử (Test Suite Expansion)
* **Thời gian:** 2 ngày  
* **Độ ưu tiên:** P1
* **Công việc cụ thể:**
  1. Viết Unit Tests cho các Riverpod Controllers:
     - `test/features/inbound/presentation/controllers/batch_scanner_controller_test.dart`
     - `test/features/outbound/presentation/controllers/pick_verify_controller_test.dart`
     - `test/features/reports/presentation/controllers/reports_controller_test.dart`
     - `test/features/ai_assistant/presentation/controllers/ai_chat_controller_test.dart`
  2. Viết Widget Tests cho các luồng then chốt: `LoginScreen`, `StockOverviewScreen`, `ReportsScreen`.
  3. Đảm bảo toàn bộ test cases đạt 100% pass và `flutter analyze` báo 0 issues.

---

### 🔹 Giai đoạn 4: Thử nghiệm Thiết bị Thật, Build APK Release & Nghiệm Thu
* **Thời gian:** 1.5 ngày  
* **Độ ưu tiên:** P0
* **Công việc cụ thể:**
  1. Cài đặt và thử nghiệm trên điện thoại Android vật lý:
     - Kiểm tra quét camera mã vạch và OCR trong điều kiện thiếu sáng.
     - Kiểm tra micro thu âm giọng nói tiếng Việt.
     - Kiểm tra chia sẻ file PDF/Excel qua ứng dụng ngoài.
  2. Đóng gói sản phẩm:
     ```bash
     flutter build apk --release
     ```
  3. Hoàn thiện ảnh chụp màn hình thực tế và số liệu nghiệm thu vào tài liệu báo cáo `docs/BAO_CAO_SMART_WMS_AI_ASSISTANT.md`.

---

## 4. Danh Sách Nhiệm Vụ Cần Làm Ngay (Immediate Next Tasks)

1. **Task 1:** Hiện thực hóa `BatchScanScreen` với `MobileScanner` và bộ đếm cộng dồn mã vạch.
2. **Task 2:** Hiện thực hóa `OcrScanScreen` với `google_mlkit_text_recognition` và `OcrTextExtractor`.
3. **Task 3:** Hoàn thiện `InboundDetailScreen` và `OutboundDetailScreen`.
4. **Task 4:** Bổ sung CRUD vị trí kho trên `LocationListScreen`.
