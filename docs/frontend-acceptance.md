# Nghiệm thu frontend Smart WMS

Cập nhật 13/10/2026. FE dùng dữ liệu repository/contract; không xác nhận tích hợp backend trong đợt này.

## Đồng bộ thiết kế các màn còn lại — 13/10/2026

Phạm vi bổ sung sau đợt chốt ba màn và sửa điều hướng scanner: danh sách sản phẩm/vị trí, chi tiết sản phẩm/phiếu nhập/xuất, báo cáo, trợ lý AI, hồ sơ, đăng nhập và đăng ký. Màn danh sách/form phiếu dùng chung, Dashboard và ba màn scanner giữ phần đã nghiệm thu.

- Dùng cùng `WorkspaceHeader`, `workspacePadding` và nội dung tối đa 1200px; hồ sơ tối đa 760px, trợ lý AI 960px. Bỏ AppBar lặp bên trong shell ở các trang nghiệp vụ, giữ topbar/sidebar/bottom nav chung. Trang chi tiết có đường về danh sách rõ ràng.
- Sản phẩm và vị trí đặt tiêu đề, hành động thêm và tìm kiếm theo cùng thứ bậc; trường tìm kiếm tối đa 420px, có tổng kết quả, vị trí có đường phân tách và gợi ý khi không tìm thấy. Quyền Admin và dialog CRUD giữ theo luồng hiện có.
- Báo cáo đặt lọc/xuất file cạnh nội dung, tên loại phiếu hiển thị tiếng Việt. Hồ sơ hiển thị tên vai trò tiếng Việt. Trợ lý AI dùng khung nội dung vừa phải và khóa thao tác xóa khi phiên chưa có tin nhắn. Đăng nhập/đăng ký dùng cùng nhận diện kho và khoảng cách; đăng ký có nút quay lại đầu trang.
- Đã xem bản render Chrome headless ở 1440×900 và 390×844 cho toàn bộ nhóm màn trên. Tên dài của sản phẩm trong preview xuống dòng đúng, không thấy tràn; form, topbar và thanh điều hướng mobile còn dùng được. Ảnh lưu tại `docs/screenshots/sync-*.png`; kịch bản trong `tool/visual_remaining.json`.
- Format đã chạy; `flutter analyze --no-pub`: 0 issue; `flutter test --no-pub`: 103/103 pass, gồm 2 widget test mới cho đăng ký/quay về đăng nhập ở hai chiều rộng. Hai entry point preview/production build web JavaScript thành công từ cùng code. Không thay BE/schema/RPC/Edge Functions/Supabase config.
- Preview giữ phiên đăng nhập fixture trong bộ nhớ; reload thực về login. Kiểm tra route không có stack là regression widget, không thay cho kiểm chứng reload khi có Supabase session production. Chưa kiểm chứng camera, micro hoặc tích hợp backend thật trên thiết bị.

## Sửa điều hướng scanner và tiếp tục đồng bộ frontend — 13/10/2026

- Tra mã hàng, OCR và Pick Verify dùng chung `ScannerBackButton`: mũi tên trái tiêu đề, tooltip/nhãn accessibility “Quay lại”, vùng chạm tối thiểu 48×48px trên desktop/mobile.
- GoRouter pop màn trên stack; khi không có stack, Tra mã về `/`, OCR về `/batch-scan`, Pick Verify về `/outbound/:orderId`. Có xử lý entry scan trùng để không quay lại chính màn scan.
- Dashboard/menu mở Tra mã bằng push; Tra mã mở OCR bằng push; chi tiết xuất mở Pick Verify bằng push. Form nhập/xuất không có lối mở scanner riêng trước đợt này; menu Tra mã giữ nguyên widget/state form phía dưới, gồm ghi chú/số lượng. Không sửa cấu trúc router, backend hoặc generated.
- Tiếp tục đồng bộ ba màn toàn màn hình với thiết kế nghiệp vụ hiện có: dùng `workspacePadding` 16px mobile/24px desktop, nội dung tối đa 1200px, giữ AppBar/theme và các thao tác camera/tra cứu/kết quả. Đây là phạm vi đồng bộ bổ sung của đợt này, chưa đánh dấu toàn frontend hoàn thành.
- Format đã chạy; `flutter analyze --no-pub`: 0 issue; `flutter test --no-pub`: 101/101 pass, gồm 11 regression mới về dashboard, menu/form nhập/xuất, OCR giữ input, fallback, entry trùng và Pick Verify. Test dùng router thật của ứng dụng; route được dựng lại không có imperative stack để kiểm tra trạng thái tương đương reload đã đăng nhập.
- Preview (`lib/main_preview.dart`) và production (`lib/main.dart`) đều build web JavaScript thành công. Cảnh báo Wasm dry-run từ dependency `image-4.3.0` vẫn tồn tại; không xác nhận Wasm.
- Chrome headless thật: đã bấm dashboard → scan → quay lại; form có ghi chú → menu scan → OCR → quay lại scan giữ mã → quay lại form giữ ghi chú; mở scan/OCR/Pick Verify qua hash URL và kiểm tra đích dự phòng. Đã xem ảnh desktop 1440×900 và mobile 390×844. Khi chuyển trực tiếp khỏi form có dữ liệu, guard “Rời phiếu chưa lưu?” vẫn hoạt động.
- Reload thật trên preview về login do phiên đăng nhập fixture chỉ nằm trong bộ nhớ. Không tuyên bố đã kiểm chứng reload với phiên Supabase production; fallback không có stack được phủ bằng regression. Camera trên thiết bị thật chưa kiểm tra trong đợt này.

Bằng chứng: [scan desktop](screenshots/scan-back-desktop.png), [scan mobile](screenshots/scan-back-mobile.png), [OCR desktop](screenshots/ocr-back-desktop.png), [OCR mobile](screenshots/ocr-back-mobile.png), [Pick Verify mobile](screenshots/pick-back-mobile.png), [scan giữ mã](screenshots/scan-retained-input-desktop.png), [form giữ ghi chú](screenshots/scan-retained-form-desktop.png). Kịch bản CDP nằm trong `tool/visual_navigation.json`; helper bổ sung thao tác tap tọa độ để kiểm tra sidebar không xuất node semantics trong bản render này.


## Đợt chốt thiết kế ba màn — 13/10/2026

Phạm vi: app shell, Dashboard Admin, danh sách phiếu nhập và form tạo phiếu nhiều dòng. Hai widget phiếu dùng chung với xuất kho được giữ dùng chung; không mở đợt thiết kế riêng cho xuất kho hoặc các màn khác. Chưa có người dùng duyệt thiết kế, chưa đánh dấu toàn frontend/17 user stories hoàn thành.

Không có Git metadata trong workspace; không git init, clone, reset, commit, push hoặc deploy. Giữ các repository, quy tắc nghiệp vụ và cấu hình backend. Không có screenshot cũ được đính kèm trong ngữ cảnh phiên này để đối chiếu; ảnh bên dưới được chụp từ bản render mới.

### Thiết kế và hành vi

- Light mặc định: #F5F7FB, panel trắng, chữ #172B4D, hành động #2563EB. Sidebar #14253D, 240px, có nhóm điều hướng và mục chọn nền xanh; topbar 64px có vai trò tiếng Việt, hồ sơ/đăng xuất và badge nhỏ Dữ liệu mẫu.
- Dashboard: KPI có nhãn/đơn vị/icon; số SKU có tồn chỉ đếm bản ghi thực có >0; tổng thực có chia theo đơn vị. Biểu đồ 210px có trục SKU/số lượng, lọc đơn vị 200px và tooltip; desktop đặt cạnh phiếu nháp/cảnh báo. Giữ drilldown sản phẩm và phiếu, không dựng tỷ lệ tăng trưởng.
- Danh sách: tìm kiếm tối đa 420px, lọc 220px; bảng khi vùng nội dung >=900px, item trên màn nhỏ. Cột chỉ gồm mã, ngày tạo, trạng thái, ghi chú, thao tác; badge có chữ, hover/focus, mã và hàng mở chi tiết. Tổng kết quả tính trong tập đã tải, chưa có phân trang server.
- Form: thông tin phiếu và sản phẩm tách section; dòng desktop nằm ngang, mobile nhóm trường. Key ổn định giữ dữ liệu khi xóa dòng. Tổng hợp riêng theo đơn vị, lỗi sát trường và giữ qua breakpoint. Thanh lưu/hủy cố định, loading/khóa gửi; repository lỗi giữ dữ liệu và không báo thành công. GoRouter onExit xác nhận khi rời phiếu có thay đổi, kể cả điều hướng shell. Dialog cuộn được.
- Preview dùng cùng App/router/screen/controller, chỉ thay dependency. `showcase: true` chỉ tại entry point preview bổ sung tên dài và đủ 5 trạng thái nhập; fixture mặc định của test nghiệp vụ giữ nguyên.

### Kiểm tra mới trên bản chốt

| Kiểm tra | Kết quả |
|---|---|
| Format các Dart đã sửa | Đã chạy |
| dart run build_runner build | Thành công sau thay đổi router; không sửa generated bằng tay |
| flutter analyze --no-pub | 0 issue |
| flutter test --no-pub | 90/90 pass |
| flutter build web --no-pub -t lib/main_preview.dart | Thành công, build/web |
| flutter build web --no-pub --output build/web-production | Thành công, target lib/main.dart, build/web-production |

Cả hai web build là JavaScript; Wasm dry-run cảnh báo từ dependency image-4.3.0, không phải lỗi build và không tuyên bố đã build Wasm.

19 test mới kiểm tra tên dài, ba chiều rộng 390/820/1440 với text scale 130%, dark theme, tìm/lọc/xóa lọc, loading/lỗi/retry, rỗng, xóa dòng giữ số lượng, rời form, lưu lỗi và khóa gửi lặp. Test cũ validation được cập nhật cho footer/menu mới và kiểm tra lỗi không mất khi resize; không xóa test để đạt xanh.

### Bằng chứng trực quan

Chrome headless thật chạy bản JavaScript preview tại http://127.0.0.1:8091, điều khiển qua CDP bằng `tool/visual_qa.py`; không dựng mock ảnh. Playwright MCP thiếu extension; Chrome DevTools MCP lỗi viewport/path lưu ảnh nên bộ ảnh nghiệm thu được chụp bằng Chrome riêng. Đã xem và sửa qua ảnh: sidebar che màu chọn, bảng ở chiều rộng trung gian, căn lề header mobile, thanh lưu/hủy và validation mất khi đổi breakpoint.

| Màn | Desktop 1440×900 | Mobile 390×844 | Trung gian 820×900 |
|---|---|---|---|
| Dashboard | [Ảnh](screenshots/dashboard-desktop.png) | [Ảnh](screenshots/dashboard-mobile.png) | [Ảnh](screenshots/dashboard-tablet.png) |
| Danh sách nhập | [Ảnh](screenshots/inbound-desktop.png) | [Ảnh](screenshots/inbound-mobile.png) | [Ảnh](screenshots/inbound-tablet.png) |
| Form nhiều dòng | [Ảnh](screenshots/form-desktop.png) | [Ảnh](screenshots/form-mobile.png) | [Ảnh](screenshots/form-tablet.png) |
| Validation | [Ảnh](screenshots/form-validation-desktop.png) | [Ảnh](screenshots/form-validation-mobile.png) | Widget test |
| Dropdown trạng thái | [Ảnh](screenshots/inbound-dropdown-desktop.png) | [Ảnh](screenshots/inbound-dropdown-mobile.png) | — |

| Bổ sung | Desktop | Mobile |
|---|---|---|
| Dropdown sản phẩm | [Ảnh](screenshots/form-dropdown-desktop.png) | [Ảnh](screenshots/form-dropdown-mobile.png) |
| Form đã điền hai đơn vị | [Ảnh](screenshots/form-filled-desktop.png) | [Ảnh](screenshots/form-filled-mobile.png) |
| Dark dashboard | [Ảnh](screenshots/dashboard-dark-desktop.png) | [Ảnh](screenshots/dashboard-dark-mobile.png) |
| Dark danh sách | [Ảnh](screenshots/inbound-dark-desktop.png) | [Ảnh](screenshots/inbound-dark-mobile.png) |
| Dark form | [Ảnh](screenshots/form-dark-desktop.png) | [Ảnh](screenshots/form-dark-mobile.png) |

[Tổng hợp sau cuộn](screenshots/form-summary-mobile.png) ghi 3 cái và 5 đôi riêng biệt. [Dialog rời form 390×500](screenshots/form-leave-dialog-mobile.png), [hover hàng bảng](screenshots/inbound-hover-desktop.png), [focus bằng Tab](screenshots/inbound-focus-desktop.png), [tooltip biểu đồ](screenshots/dashboard-chart-tooltip.png).


Tương phản tính theo WCAG sRGB: #172B4D/trắng 14,10:1; trắng/#2563EB 5,17:1; #D5DEEC/#14253D 11,37:1; nhãn nhóm #BBCADD/#14253D 9,26:1. Dark theme dùng ColorScheme riêng, có widget test và ảnh render riêng.

Giới hạn: loading/error/retry/empty/lưu thất bại được kiểm tra bằng widget test thay dependency, chưa chụp mọi trạng thái trên browser. Kiểm tra bàn phím desktop, Escape đóng dropdown và Tab/focus; viewport thấp mô phỏng thiếu chiều cao, không phải bàn phím ảo trên thiết bị thật. Chưa xác minh camera/OCR/micro/backend thật. Reload/đóng tab browser có thể mất draft; xác nhận rời form bao phủ điều hướng GoRouter trong ứng dụng. Không tuyên bố đã nghiệm thu thiết bị thật hoặc toàn bộ ứng dụng.

Danh sách file sửa: `lib/app/router/main_shell.dart`, `lib/app/router/app_router.dart` (và generated do build_runner), `lib/app/theme/app_colors.dart`, `lib/app/theme/app_theme.dart`, `lib/app/theme/theme_controller.dart`, `lib/core/widgets/workspace_layout.dart`, `lib/core/widgets/confirm_dialog.dart`, `lib/features/inventory/presentation/widgets/stock_overview_screen.dart`, `lib/features/orders/presentation/widgets/order_list_screen.dart`, `order_form_screen.dart`, `order_labels.dart`, `lib/core/preview/preview_repository.dart`, `lib/main_preview.dart`, hai test frontend, tài liệu và công cụ/ảnh QA. Không thay backend/schema/RPC/Edge Functions/Supabase config.

## Chạy chế độ xem trước

```powershell
Set-Location -LiteralPath 'D:\InventoryAssistant-main'
& 'D:\flutter\bin\flutter.bat' run -d chrome --no-pub -t lib/main_preview.dart
```

Không cần đọc/sửa .env hoặc khởi tạo Supabase trong preview. Tài khoản fixture:

| Vai trò | Email | Mật khẩu |
|---|---|---|
| Admin | admin@preview.local | Bất kỳ chuỗi không rỗng |
| Manager | manager@preview.local | Bất kỳ chuỗi không rỗng |
| Nhân viên | staff@preview.local | Bất kỳ chuỗi không rỗng |

Đăng xuất qua Hồ sơ để đổi vai trò. Preview có nhãn rõ, dữ liệu chỉ trong bộ nhớ; refresh/hot restart tạo lại fixture.

Chế độ thật giữ entry point mặc định:

```powershell
Set-Location -LiteralPath 'D:\InventoryAssistant-main'
& 'D:\flutter\bin\flutter.bat' run -d chrome --no-pub
```

Dùng cấu hình Supabase hiện có, chưa xác minh tích hợp thật trong đợt này. CRUD và workflow mới có pending adapter, không báo lưu/duyệt thành công giả.

## Kịch bản kiểm tra theo vai trò

1. Login/register: trường trống, email sai, mật khẩu đăng ký ngắn; xem mật khẩu; kiểm tra loading và lỗi.
2. Admin: Sản phẩm → tìm SKU/mã vạch → chi tiết/tồn → sửa hoặc thêm sản phẩm mới. Xóa sản phẩm/vị trí đã có tồn hoặc tham chiếu phải bị từ chối; thử thêm một bản ghi chưa được tham chiếu rồi xóa với xác nhận.
3. Vị trí: dùng sidebar desktop hoặc drawer mobile → tìm khu/kệ/mã → xem chi tiết → thêm/sửa với Admin. Sức chứa tùy chọn phải hữu hạn và dương.
4. Nhân viên: không có nút CRUD sản phẩm/vị trí; phiếu chỉ của preview-staff, không thấy PN-XEM-002 của người khác. Guard FE không thay phân quyền server.
5. Nhập: tạo phiếu, chọn sản phẩm/vị trí, số lượng >0, thêm/xóa dòng, ghi chú, lưu nháp; kiểm tra chi tiết. Admin/Manager duyệt/từ chối phiếu Nháp. Tồn không thay đổi.
6. Xuất: thử 71 đôi găng tay tại A-01-01-01 phải lỗi (80 thực có −10 giữ chỗ =70); thử hai dòng 40+31 cũng lỗi. Lưu phiếu hợp lệ và mở đối soát mã, thử sai mã/quá số lượng. Số đếm chỉ trong phiên.
7. Dashboard: xem chỉ số theo đơn vị, cảnh báo băng keo dưới tồn an toàn; lọc đơn vị biểu đồ, mở chi tiết từ cảnh báo.
8. Báo cáo: lọc ngày tạo phiếu, bỏ lọc; tồn hiện tại không đổi theo khoảng ngày; xuất Excel/PDF. Excel sheet phạm vi ghi rõ không phải ledger đầu/cuối kỳ.
9. Tra mã: thủ công 893000000001, sai mã, mô phỏng trong preview; mở chi tiết. Camera kiểm tra riêng với thiết bị/quyền thực, không coi fixture là scan thật.
10. OCR: dán LOT: ABC123 và HSD: 25/12/2027 → phân tích; chỉ mô phỏng parser, không đọc ảnh thực.
11. AI preview: gõ “tồn kho” hoặc “phiếu nhập nháp” / “phiếu xuất nháp”. Fixture single-line dùng 5 đôi găng tay, có nhãn mô phỏng. Mở bản nháp, sửa số lượng/vị trí, hủy hoặc xác nhận lưu nháp. Voice chỉ điền văn bản, cần bấm gửi.
12. Hồ sơ: đổi sáng/tối/hệ thống trong phiên; đăng xuất; thử desktop 1440×900 và mobile 390×844, bàn phím/text scaling.

## Kiểm tra tự động

Kết quả đợt trước, trước đợt thiết kế ba màn:

| Lệnh / kiểm tra | Kết quả |
|---|---|
| dart run build_runner build | Thành công, generated do tool sinh |
| flutter analyze --no-pub | 0 issue |
| flutter test --no-pub | 71/71 pass (28 cũ + 43 mới) |
| flutter build web --no-pub | Thành công, output build/web |
| Widget render 13 màn hình tại 390px/1440px | Pass, không ghi nhận layout exception/overflow ở trạng thái fixture được kiểm tra |

Web build có cảnh báo Wasm dry-run từ dependency image-4.3.0; bản JavaScript build thành công. Không đổi dependency hoặc tuyên bố đã build Wasm.

Test bổ sung gồm role/ownership, tổng dòng xuất trùng và tồn giữ chỗ, draft idempotency, review không đổi tồn, AI loading/lỗi/preview không lưu, ngày lọc/Excel, form thêm sản phẩm, trạng thái rỗng và regression lỗi → retry → dữ liệu.

## Kiểm tra trực quan đợt trước và giới hạn

- Chrome DevTools đã mở bản preview localhost, xem screenshot login desktop 1440×900, dashboard desktop và login mobile 390×844.
- Playwright MCP không khả dụng vì thiếu extension; không cài thêm.
- Các lần screenshot mobile tiếp theo gặp CDP timeout; chưa kiểm tra trực quan đầy đủ mọi màn hình/trạng thái. Widget test không thay việc nghiệm thu bằng mắt.
- Chưa có bằng chứng thiết bị thật cho camera barcode, OCR ảnh, micro/voice hoặc chia sẻ file native.
- Hồ sơ chỉ đọc; theme chưa lưu qua phiên; danh mục/warehouse chưa có model.
- Báo cáo hiện là snapshot tồn + lịch sử header phiếu, không phải sổ nhập/xuất/tồn.
- Backend Supabase/Edge Functions/RPC và authorization cuối cùng chưa được xác minh; xem frontend-backend-contracts.md.
