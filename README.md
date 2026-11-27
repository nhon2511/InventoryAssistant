# Smart WMS

Flutter Android/Web dùng Supabase Auth để lấy phiên đăng nhập và gửi Bearer JWT tới NestJS cho danh mục, tồn kho và phiếu nhập/xuất. Xem [kiến trúc](docs/system-architecture.md), [contract](docs/frontend-backend-contracts.md) và [nghiệm thu CP8](docs/audits/CP8_ACCEPTANCE_2026-11-27.md).

## Trạng thái kiểm chứng

- Flutter và NestJS qua test offline, analyze/lint và build Web JavaScript/APK debug. Đây không phải bằng chứng chạy nghiệp vụ trên PostgreSQL thật.
- Dashboard đọc snapshot từ NestJS và có nút tải lại; Realtime qua Supabase chưa được xác minh với các transaction NestJS.
- Báo cáo hiển thị tồn hiện tại và header phiếu trong tập API trả về. Không có báo cáo đầu/cuối kỳ hoặc lịch sử biến động theo ledger.
- Quét barcode điền số lượng thực tế vào form xác nhận; camera thật trên Android/Web chưa được nghiệm thu. OCR ảnh chạy trên Web; Android có nhập LOT/HSD thủ công. LOT/HSD ở phiếu đã duyệt chỉ là preview vì API confirm không lưu hai trường này.
- AI production trả lỗi chưa khả dụng: source/deployment và quyền của Edge Function chưa được chứng minh. Voice chỉ chuyển tiếng nói thành text, người dùng tự bấm Gửi.

## Chạy bản xem trước an toàn

Bản preview dùng fixture trong bộ nhớ, không cần Supabase/NestJS. Tài khoản thử: `admin@preview.local`, `manager@preview.local`, `staff@preview.local`; mật khẩu là bất kỳ chuỗi không rỗng. Không dùng kết quả preview làm bằng chứng dữ liệu production.

```powershell
flutter pub get
flutter run -d chrome -t lib/main_preview.dart
```

## Chạy Flutter với backend test/dev riêng

Tạo `.env` cục bộ từ `.env.example`; không commit file này. Chỉ dùng Supabase Auth project đã xác định an toàn và NestJS URL có thể truy cập từ đúng nền tảng. [Hướng dẫn backend](backend/README.md) mô tả phần server. Không dùng project production cho nghiệm thu.

```powershell
# Web trên cùng máy với NestJS
flutter run -d chrome --dart-define=NESTJS_BASE_URL=http://localhost:3000

# Android emulator: 10.0.2.2 trỏ tới máy host
flutter run -d emulator-5554 --dart-define=NESTJS_BASE_URL=http://10.0.2.2:3000

# Android device: thay hostname bằng địa chỉ LAN/DNS truy cập được từ điện thoại
flutter run -d <device-id> --dart-define=NESTJS_BASE_URL=https://wms-api.example.test
```

Backend URL release cần HTTPS; Web cần CORS cho origin của app. Build thành công không xác nhận URL, JWT, role, schema hoặc dữ liệu thật.

## Quality gates offline

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter build web --no-pub
flutter build apk --debug

Set-Location backend
npm run prisma:validate
npm run prisma:generate
npm test
npm run test:e2e
npm run lint
npm run build
```

`test:e2e` hiện dùng mock/offline. Không chạy `test:db` khi chưa có test target riêng, đủ guard theo [B7](docs/audits/TASK-DB-04D_B7_INTEGRATION_READINESS.md), schema canonical được duyệt và kế hoạch reset. Các SQL local trong `supabase/` không mặc nhiên là migration chuẩn.

## Demo

Xem [kịch bản demo CP8](docs/audits/CP8_ACCEPTANCE_2026-11-27.md). Demo preview nên tập trung vào login/role, catalog, form nhiều dòng, validation, scan nhập tay, snapshot, lọc ngày báo cáo và thông báo AI chưa khả dụng. Demo giao dịch thật cần project test đã xác minh và một đợt nghiệm thu riêng.
