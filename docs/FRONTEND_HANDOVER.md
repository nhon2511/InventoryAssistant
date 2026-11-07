# Bàn giao frontend Smart WMS

Cập nhật: **18/10/2026**. Nhánh bàn giao `feature/frontend-web` lấy từ `main` của repo chung và thêm source FE hiện hành trong `D:\InventoryAssistant-main`. Đây là bàn giao mã Flutter và tài liệu để nhóm tiếp tục tích hợp BE, chưa phải nghiệm thu toàn bộ nghiệp vụ.

Tài liệu chi tiết: [nghiệm thu FE và bằng chứng](frontend-acceptance.md), [contract FE–BE](frontend-backend-contracts.md), [kế hoạch tiếp theo](../KE_HOACH_THUC_HIEN_TIEP_THEO.md), [user stories](USER_STORIES.md).

## Phạm vi và trạng thái

| Nhóm màn hình / thao tác | FE đã triển khai | Chạy trong preview | Đã xác minh BE thật | Còn chờ BE / kiểm chứng |
|---|---|---|---|---|
| Đăng nhập, đăng ký, hồ sơ, đổi theme, đăng xuất, điều hướng theo vai trò | Có UI, validation và trạng thái lỗi | Có, 3 vai trò fixture | Chưa | Supabase Auth, xác minh email, session và phân quyền server; cập nhật hồ sơ chưa có |
| Dashboard và shell desktop/mobile | Chỉ số tồn theo đơn vị, cảnh báo tồn thấp, drilldown, quick actions | Có | Chưa | Snapshot/realtime và quyền dữ liệu thật; chưa có biểu đồ biến động từ ledger |
| Sản phẩm, tồn và vị trí | Danh sách, tìm kiếm, chi tiết; form thêm/sửa/xóa Admin với xác nhận | Có | Chưa | Production CRUD adapter, unique constraint, RLS; chưa có category/warehouse entity |
| Phiếu nhập/xuất | Danh sách, lọc, chi tiết, form nhiều dòng, ghi chú, nháp, duyệt/từ chối; kiểm tra số lượng tại FE | Có | Chưa | Lưu nguyên tử/idempotent, review compare-and-set, transaction tồn; datasource phiếu xuất thật chưa tải line items |
| Tra mã, Pick Verify và OCR | Nhập mã, UI camera, đối soát đếm trong phiên; OCR parser văn bản dán | Có, có mô phỏng gắn nhãn | Chưa | Camera và OCR ảnh thật trên thiết bị, lưu kết quả đối soát, batch receiving |
| Báo cáo | Tồn hiện tại, header phiếu lọc ngày tạo, xuất Excel/PDF từ dữ liệu nhận được | Có | Chưa | Ledger cho tồn đầu/cuối kỳ và nhập/xuất thực tế; xác minh font PDF/chia sẻ trên thiết bị |
| Trợ lý AI/voice | Chat, loading/lỗi/retry, bản nháp một dòng cần xác nhận; voice điền văn bản | Có, AI fixture gắn nhãn | Chưa | Edge Functions, micro thật, NLU nhiều dòng/lot/expiry và quyền server |

"Có UI" hoặc "chạy trong preview" không đồng nghĩa hoàn thành user story. Các phần còn thiếu và giới hạn cụ thể nằm trong [nghiệm thu FE](frontend-acceptance.md) và [contract FE–BE](frontend-backend-contracts.md).

## Thay đổi chính so với `main`

- Entry point fixture [main_preview.dart](../lib/main_preview.dart), dữ liệu và AI preview trong [core/preview](../lib/core/preview), với override provider tại composition root. Ứng dụng thật giữ [main.dart](../lib/main.dart) và các datasource/repository Supabase trong `lib/features/*/data/`.
- Router, shell, theme và màn theo vai trò tại [app/router](../lib/app/router), [app/theme](../lib/app/theme), [auth](../lib/features/auth), [dashboard](../lib/features/inventory/presentation/widgets/stock_overview_screen.dart).
- Tìm kiếm, CRUD FE và phiếu nhiều dòng tại [inventory](../lib/features/inventory), [inbound](../lib/features/inbound), [outbound](../lib/features/outbound), [orders](../lib/features/orders). Production dùng các pending adapter cho capability chưa có API, nên trả lỗi có kiểm soát thay vì báo lưu giả.
- Scan/OCR/AI, báo cáo và kiểm tra tương ứng tại [lib/features](../lib/features), [test/frontend](../test/frontend), [tool](../tool). Cấu hình Flutter và dependency: [pubspec.yaml](../pubspec.yaml), [pubspec.lock](../pubspec.lock), `web/`, `assets/`.
- Bằng chứng trực quan và điều kiện kiểm tra: [frontend-acceptance.md](frontend-acceptance.md), [screenshots](screenshots), [frontend-backend-contracts.md](frontend-backend-contracts.md).

Các file backend, Android/iOS và file chỉ có trên `main` được giữ trong checkout; đợt này không đổi schema/RPC/Edge Functions.

## Luồng mã và cách thay nguồn dữ liệu

Widget trong `presentation` theo dõi Riverpod controller/provider. Controller gọi use case trong `domain`, use case làm việc qua repository contract trả `Either<Failure, T>`, còn implementation trong `data` gọi datasource/Supabase và ánh xạ lỗi. GoRouter quản lý navigation; widget hiển thị lỗi dễ hiểu. [Kiến trúc](system-architecture.md) và [quy chuẩn mã](code-standards.md) mô tả cấu trúc chung.

`main_preview.dart` tạo `PreviewRepository` trong bộ nhớ và override các provider ở composition root. Khi nối BE, giữ UI/controller/use case, triển khai hoặc nối các repository contract trong [core/di](../lib/core/di) với datasource thật. Ưu tiên [InventoryMaintenanceRepository](../lib/features/inventory/domain/repositories/inventory_maintenance_repository.dart) và [OrderWorkflowRepository](../lib/features/orders/domain/repositories/order_workflow_repository.dart); đối chiếu từng method trong [contract](frontend-backend-contracts.md). Không xem guard và kiểm tra tồn tại FE là thay thế RLS/transaction server.

## Chạy và thử preview

Tại root checkout, với Flutter SDK ở `D:\flutter\bin` trên máy bàn giao:

```powershell
Copy-Item .env.example .env # chỉ tạo asset placeholder cục bộ
& 'D:\flutter\bin\flutter.bat' pub get
& 'D:\flutter\bin\flutter.bat' run -d chrome -t lib/main_preview.dart
```

Preview không kết nối Supabase; `.env` placeholder cục bộ chỉ cần vì `pubspec.yaml` khai báo asset `.env`. Chọn `admin@preview.local`, `manager@preview.local` hoặc `staff@preview.local`, nhập mật khẩu bất kỳ không rỗng. Đăng xuất ở Hồ sơ rồi đăng nhập email khác để đổi vai trò. Fixture và phiên chỉ ở bộ nhớ: **reload/hot restart đặt lại dữ liệu và quay về đăng nhập**.

Ứng dụng chính cần `.env` cục bộ theo [`.env.example`](../.env.example) với Supabase URL và anon key hợp lệ; `.env` thật không nằm trong Git:

```powershell
Copy-Item .env.example .env
# Điền thông tin Supabase cục bộ vào .env
& 'D:\flutter\bin\flutter.bat' run -d chrome -t lib/main.dart
```

Khi sửa provider/model có annotation, chạy `D:\flutter\bin\dart.bat run build_runner build` và không chỉnh `.g.dart` bằng tay.

## Kiểm tra

| Ngày, target | Lệnh | Kết quả |
|---|---|---|
| 13/10/2026, source FE trước bàn giao | `flutter analyze --no-pub`, `flutter test --no-pub`, build web JavaScript preview và production | Theo [báo cáo trước](frontend-acceptance.md): analyze 0 issue, **103/103** test pass, hai build thành công. Đây là kết quả cũ, không phải xác minh trên checkout bàn giao. |
| 18/10/2026, checkout nhánh bàn giao | `flutter.bat --version`, `flutter.bat pub get`, `dart.bat --version` | SDK không trả output trong thời gian chờ và phải dừng; vì vậy chưa chạy lại analyze/test/build trên checkout này. Không xác nhận kết quả 103 test cho ngày 18/10. |

Các ảnh trong [frontend-acceptance.md](frontend-acceptance.md) là bằng chứng render của đợt trước. Ví dụ: [Dashboard desktop](screenshots/dashboard-desktop.png), [form nhập mobile](screenshots/form-mobile.png), [scan mobile](screenshots/scan-back-mobile.png), [AI desktop](screenshots/sync-ai-desktop.png). Ảnh preview không chứng minh camera, backend hay thiết bị thật.

## Việc nhóm BE cần tiếp tục

1. Thống nhất contract/schema cho danh mục, warehouse, profile và các capability còn thiếu; giữ interface FE hiện có nếu phù hợp.
2. Nối CRUD sản phẩm/vị trí với validation, unique constraint, auth/RLS server; kiểm thử dữ liệu và lỗi thật.
3. Nối nháp phiếu nguyên tử nhiều dòng với request ID idempotent; review trạng thái compare-and-set, audit và ownership server; tải line items phiếu xuất.
4. Triển khai giao dịch nhập/xuất, reservation, đối soát, ledger và realtime nhất quán; kiểm tra cạnh tranh và retry trên server.
5. Kiểm chứng Auth/session/email confirmation, Edge Functions AI, dữ liệu báo cáo và quyền truy cập với môi trường staging.
6. Cùng FE/QA kiểm tra camera, OCR ảnh, micro, PDF/chia sẻ và các màn/nghiệp vụ còn thiếu trên thiết bị đích trước khi đóng user stories.
