# Báo cáo bàn giao phần Frontend Smart WMS

**Phạm vi:** Flutter Web responsive cho desktop/mobile. Báo cáo này ghi nhận phần giao diện và luồng FE đã hoàn thiện trong nhánh làm việc hiện tại; không xác nhận backend/Supabase production.

## 1. Phần đã thực hiện

### Quét mã trong phiếu nhập/xuất

- Màn batch scan hỗ trợ camera khi người dùng chủ động bật, nhập barcode thủ công, cộng lượt quét trùng và xóa phiên có xác nhận.
- Từ form nhập/xuất có thể mở scanner. Khi chọn đưa mã vào phiếu, FE tìm mã trong danh sách sản phẩm đã tải, thêm hoặc cộng số lượng cho sản phẩm khớp; mã không khớp được báo lại.
- Quét chỉ điền form trong bộ nhớ. Vị trí vẫn do người dùng chọn; không ghi tồn kho và không giả báo lưu phiếu thành công.
- Tra một mã có route riêng; scanner và màn tra mã có điều hướng dự phòng.

### Số lô và hạn sử dụng

- Form nhập có số lô và hạn sử dụng trên từng dòng; hạn sử dụng chọn bằng date picker và được kiểm tra định dạng.
- Màn parser văn bản nhãn có thể trả kết quả để người dùng xác nhận điền vào dòng nhập. Đây là parser văn bản, không phải nhận diện ảnh/camera.
- Chi tiết phiếu hiển thị số lô và hạn sử dụng nếu repository trả về các trường này.

### Tùy chọn giao diện trên web

- Chế độ Sáng/Tối/Theo hệ thống được lưu bằng `shared_preferences` trên thiết bị/trình duyệt hiện tại và khôi phục khi mở app lại.
- Nếu browser storage không khả dụng, theme vẫn dùng được trong phiên hiện tại.

### Tài liệu và điều hướng

- Cập nhật nghiệm thu FE và contract FE–BE để ghi rõ hành vi mới cùng giới hạn.
- Đánh dấu scorecard/TODO trong kế hoạch ngày 03/11 là tài liệu lịch sử, tránh nhầm với trạng thái source mới.

## 2. File liên quan

- Router/scanner: `lib/app/router/app_router.dart`, `lib/app/router/route_names.dart`, `lib/features/inbound/presentation/widgets/batch_scan_screen.dart`, `barcode_lookup_screen.dart`, `ocr_scan_screen.dart`.
- Phiếu: `lib/features/orders/presentation/widgets/order_form_screen.dart`, `order_detail_screen.dart`.
- Hồ sơ/theme: `lib/app/theme/theme_controller.dart`, `lib/features/auth/presentation/widgets/profile_screen.dart`.
- Dependency: `pubspec.yaml`, `pubspec.lock` (`shared_preferences`).
- Regression test đã thêm: `test/frontend/scanner_navigation_test.dart`.
- Tài liệu trạng thái: `docs/frontend-acceptance.md`, `docs/frontend-backend-contracts.md`, `KE_HOACH_THUC_HIEN_TIEP_THEO.md`.

## 3. Kiểm tra

- `dart analyze`: chạy trên toàn repo, kết quả **No issues found**.
- Người phát triển đã chạy `flutter pub get` và `flutter pub run build_runner build --delete-conflicting-outputs` theo báo cáo trong cuộc trao đổi; log đầu ra không có trong phiên kiểm tra này.
- Flutter test/build web và kiểm tra camera/OCR trên trình duyệt thật chưa được xác minh sau các thay đổi này.

## 4. Còn phụ thuộc backend hoặc môi trường

- OCR ảnh/camera chưa có engine hỗ trợ web trong pipeline hiện tại; màn hiện chỉ phân tích văn bản người dùng dán/nhập.
- CRUD sản phẩm/vị trí, lưu phiếu, duyệt phiếu và cập nhật tồn kho production vẫn cần adapter/API/backend tương ứng. Preview dùng repository fixture trong bộ nhớ.
- Batch scan và đối soát chỉ giữ số lượng trong phiên/form; chưa ghi transaction hoặc tồn kho.
- Cần chạy `flutter test` và build web trên môi trường có Flutter SDK hoạt động trước nghiệm thu cuối.

## 5. Hướng dẫn người tiếp nhận

1. Chạy `flutter pub get` tại thư mục gốc.
2. Chạy preview web bằng `flutter run -d chrome --no-pub -t lib/main_preview.dart`.
3. Mở Phiếu nhập → Tạo phiếu → Quét mã; nhập thử một barcode fixture nhiều lần và đưa kết quả vào form.
4. Trong dòng nhập, thử nhập số lô/hạn sử dụng hoặc mở công cụ phân tích văn bản nhãn.
5. Đổi theme trong Hồ sơ, tải lại app và kiểm tra lựa chọn đã lưu trên cùng trình duyệt.
6. Xem `docs/frontend-acceptance.md` và `docs/frontend-backend-contracts.md` trước khi tích hợp backend.

Không commit `.env`, token, credentials, dữ liệu production hoặc build output trong phần bàn giao này.
