# Tiến độ giao diện theo kế hoạch V2

## Đã triển khai trong nhánh feature/thuan-ui-foundation

- Điều hướng dưới màn hình dưới 600 px, NavigationRail từ 600 px, mở rộng nhãn từ 960 px.
- Theme token chung tại `lib/app/theme/app_tokens.dart`.
- `StatusChip`, `QuantityBadge`, `ExpiryWarningChip` tại `lib/core/widgets/status_chip.dart`.
- Trang xem thành phần `/dev/widgets`.
- Dashboard có trạng thái loading, empty, error, dữ liệu, kéo để làm mới, thẻ tổng hợp responsive và lối vào chi tiết sản phẩm.

## Khác biệt giữa repo và kế hoạch

Repo đã có kiến trúc `data/domain/presentation`, Riverpod, router, Supabase repository và các màn hình khung. Không đổi toàn bộ cây thư mục sang `view/controller/repository` để tránh phá code hiện có. Chế độ demo offline dùng mock repository cho Inventory (20 sản phẩm), Nhập kho, Xuất kho và AI Assistant; chế độ mặc định vẫn dùng Supabase.

## Việc kế tiếp của Thuận

1. Chuẩn hóa thêm Button, TextField, Dialog và các trạng thái trong Widget Gallery; trao đổi với Vũ và Khánh Hòa về API component.
2. Khi có dữ liệu giao dịch, bổ sung biểu đồ nhập/xuất bằng `fl_chart`. Chưa vẽ biểu đồ với số liệu giả.
3. Chốt schema `AiResult` với nhóm rồi triển khai card tồn kho/draft và prefill form nhập/xuất. Hiện chat có nhãn cho bản nháp, chưa tạo phiếu hoặc xác nhận phiếu.
4. Chạy `flutter analyze`, kiểm thử trên điện thoại và desktop, thêm ảnh minh chứng vào PR.

## Chạy và kiểm tra

```bash
cp .env.example .env
flutter pub get
flutter analyze
flutter run
```

Demo giao diện không cần backend:

```bash
flutter pub get
flutter run --dart-define=USE_MOCK=true
```

Điền cấu hình Supabase của nhóm vào `.env` trước khi chạy app. Truy cập `/dev/widgets` để xem component không cần dữ liệu kho. Không commit `.env` lên Git.
