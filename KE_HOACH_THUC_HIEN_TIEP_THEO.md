# Kế hoạch thực hiện tiếp theo — Smart WMS

Cập nhật: 18/10/2026. Kế hoạch ngày 13/10 bên dưới được giữ làm lịch sử triển khai FE; trạng thái bàn giao hiện tại nằm ngay sau đoạn này.

## Trạng thái bàn giao FE — 18/10/2026

- Source FE hiện hành được đưa từ `D:\InventoryAssistant-main` sang checkout riêng của repo chung trên nhánh `feature/frontend-web`, dựa trên `main` mới nhất tại thời điểm clone. Giữ lịch sử repo, file Android/iOS và các file upstream không thuộc FE.
- Trang bàn giao chính: [docs/FRONTEND_HANDOVER.md](docs/FRONTEND_HANDOVER.md). Bằng chứng nghiệm thu và contract chi tiết ở các tài liệu được liên kết từ trang đó.
- Preview đã có UI và fixture cho các luồng được mô tả; chưa có bằng chứng xác minh end-to-end với Supabase thật hoặc thiết bị thật. Không đánh dấu 17 user stories hoàn thành.
- Công việc ưu tiên cho BE: hoàn thiện adapter CRUD danh mục/vị trí và phiếu; lưu phiếu nhiều dòng nguyên tử với idempotency; xác thực quyền/RLS; hoàn tất giao dịch tồn, reservation và ledger; tải line items phiếu xuất; kiểm thử auth/session và realtime bằng dữ liệu thật. Xem contract để thống nhất API và schema trước khi viết.
- Công việc còn lại cho FE/QA: duyệt giao diện với người dùng, kiểm thử camera/OCR ảnh/micro trên thiết bị, xác minh xuất/chia sẻ PDF trên nền tảng đích, bổ sung các màn hoặc nghiệp vụ chưa có trong 17 user stories sau khi BE cung cấp contract. Preview không lưu dữ liệu qua reload.
- Kiểm tra Flutter/Dart mới trên checkout bàn giao bị chặn vì SDK không trả output ngay cả với `--version`; trạng thái được ghi trong trang bàn giao. Con số 103/103 là báo cáo tại [frontend-acceptance.md](docs/frontend-acceptance.md) ngày 13/10/2026, không phải kết quả kiểm tra ngày 18/10.

Các dòng cũ bên dưới nói "không commit/push" và "sau khi người dùng duyệt FE" là giới hạn của đợt trước; người dùng đã cho phép commit/push bản bàn giao trong đợt 18/10.

## Mục tiêu và giới hạn đợt này

Giữ mục tiêu nghiệp vụ của 17 user stories trong `docs/USER_STORIES.md`: tài khoản/vai trò, sản phẩm, vị trí, tồn kho/realtime, nhập/xuất, barcode/QR, OCR, AI/voice, dashboard và báo cáo. Không đánh dấu user story hoàn thành chỉ vì có giao diện.

Giữ Flutter/Dart, Riverpod, GoRouter, Supabase và Clean Architecture feature-first. Không thay schema/RPC/Edge Functions/config Supabase, không đổi dependency version, không sửa tay generated, không commit/push/deploy. Không có Git metadata; không tự git init.

Baseline do người dùng cung cấp: analyze 0 issue, 28 test pass. Các thông tin cũ về 17 lint đã được thay thế bằng baseline này.

## Thứ tự triển khai mới

```text
Nền UI / tài khoản
  → Sản phẩm / tồn kho / vị trí
  → Phiếu nhập / xuất
  → Dashboard / báo cáo
  → Scan / AI / voice
  → Nghiệm thu frontend
  → Phối hợp tích hợp backend (sau khi người dùng duyệt FE)
```

## Kết quả frontend đã triển khai

| Phần | Frontend và hành vi | Còn chờ / không được suy diễn |
|---|---|---|
| Nền UI | Theme xanh kho hiện có, form nhất quán; sidebar desktop, drawer + bottom nav mobile; router giữ instance và refresh theo auth; login/register validation; hồ sơ, theme trong phiên, đăng xuất | Auth Supabase/session/email confirmation chưa xác minh; chưa có cập nhật hồ sơ/lưu setting |
| Sản phẩm/tồn | Tìm tên/SKU/barcode, lọc đơn vị, mở chi tiết, tồn theo vị trí; Admin thêm/sửa/xóa có validation và xác nhận | Production CRUD trả trạng thái chờ backend; không bịa API |
| Vị trí | Tìm cấu trúc zone/aisle/rack/bin/barcode, xem chi tiết, Admin form thêm/sửa và xác nhận xóa | Chưa có category/warehouse entity; không tạo schema tùy ý |
| Phiếu | Danh sách, tìm/lọc trạng thái, ownership scope FE, chi tiết/dòng hàng; form nhiều dòng, note, số nguyên dương; cộng gộp dòng xuất theo product/location và kiểm tra tồn nếu có snapshot; khóa gửi; Admin/Manager duyệt/từ chối Nháp | Lưu atomic/idempotent và review compare-and-set đang chờ adapter BE; phiếu xuất thật chưa tải line items; duyệt không đồng nghĩa cập nhật tồn |
| Dashboard | Theo vai trò; SKU có tồn, cảnh báo theo minSafetyStock; tổng theo từng đơn vị; biểu đồ lọc đơn vị + danh sách số liệu, drilldown/quick actions | Realtime backend thật chưa kiểm chứng; không có biểu đồ biến động nếu thiếu ledger |
| Báo cáo | Tồn hiện tại; lịch sử header phiếu lọc theo ngày tạo; xuất Excel/PDF từ dữ liệu nhận được, lỗi xuất có thông báo | Không báo tồn đầu/cuối kỳ hoặc lượng nhập/xuất thực tế; PDF cần font Unicode lần đầu; workflow chia sẻ phải kiểm tra theo nền tảng |
| Scan | Nhập barcode thủ công, kết quả và mở chi tiết; mô phỏng chỉ trong preview; UI MobileScanner thực tế với lỗi quyền; đối soát mã/đếm trong phiên | Camera thật chưa kiểm chứng; batch receiving/lưu đối soát/chốt tồn cần BE; OCR chỉ parser văn bản dán có nhãn mô phỏng |
| AI | Loading/lỗi/thử lại, khóa gửi lặp, voice điền văn bản; bản nháp single-line giải quyết product/location duy nhất, mở form để sửa/hủy/xác nhận | Edge Function và micro thật chưa xác minh; multi-line NLU/lot/expiry cần contract mở rộng |
| Preview | Entry point riêng `main_preview.dart`, fixture trong bộ nhớ và nhãn XEM TRƯỚC; Admin/Manager/Staff dùng cùng FE | Không thay ngầm repository thật; dữ liệu mất khi restart; AI fixture không phải LLM |

Sửa thêm lỗi controller cũ: dependency `late final` gán trong build gây lỗi khi Riverpod invalidate để retry; cho phép gán lại dependency ở controller sản phẩm/vị trí/nhập/xuất.

## Kiểm chứng đợt frontend trước

- [x] Đọc AGENTS.md, kiến trúc, code standards và hai skill UI; áp dụng smart-wms-feature và ECC dart-flutter-patterns.
- [x] Chạy build_runner sau sửa controller/router annotated; không sửa tay generated.
- [x] Test cũ 28/28 đã pass trong các đợt trung gian.
- [x] Bổ sung test scope vai trò, validation, xuất vượt tồn, idempotency, duyệt không đổi tồn, AI preview/lỗi/loading và nội dung Excel/date filter.
- [x] Bổ sung regression test lỗi/thử lại controller.
- [x] Kết quả cuối: analyze --no-pub 0 issue; test --no-pub 71/71 pass; build web --no-pub thành công. Wasm dry-run cảnh báo từ dependency image; không đổi phiên bản dependency.
- [ ] Người dùng nghiệm thu FE; chưa duyệt tích hợp BE.
- [ ] 17/17 user stories đạt tiêu chí cả FE + BE + thiết bị: chưa hoàn thành.
- [ ] APK/iOS và deploy: ngoài đợt hiện tại.

Bằng chứng render và giới hạn: `docs/frontend-acceptance.md`.
Contract bàn giao: `docs/frontend-backend-contracts.md`.

## Đợt chốt thiết kế ba màn (13/10/2026)

- [x] Shell/sidebar/topbar, dashboard, danh sách nhập và form nhiều dòng được thiết kế lại thống nhất.
- [x] Preview/production giữ dùng chung UI/router/state; bổ sung fixture dài và trạng thái chỉ trong preview.
- [x] Bổ sung regression cho responsive 390/820/1440, text scale 130%, dark, lọc, retry, xóa dòng, lưu lỗi/khóa gửi và guard rời form.
- [x] Kiểm tra mới: analyze 0 issue; 90/90 test pass; preview web build thành công. Kết quả production build và ảnh chốt ghi tại docs/frontend-acceptance.md.
- [x] Render Chrome thật và rà soát screenshot desktop/mobile/trung gian, dropdown và validation; ghi rõ giới hạn thiết bị trong tài liệu.
- [ ] Người dùng duyệt thiết kế ba màn đại diện.
- [ ] Sau duyệt mới mở đợt áp dụng cho sản phẩm, vị trí, xuất, báo cáo, scan, AI và tài khoản.
- [ ] Backend tích hợp/17 user stories hoàn chỉnh: chưa hoàn thành.

## Bước tiếp theo sau nghiệm thu FE

1. Người dùng kiểm tra Admin và nhân viên trong preview; chốt giao diện, quyền, validation và trạng thái nghiệp vụ.
2. Thống nhất contract danh mục/kho/hồ sơ nếu cần mở rộng model.
3. Người phụ trách BE cung cấp adapter CRUD, lưu/review phiếu nguyên tử, line items, ledger và authorization.
4. Kiểm thử contract thực trên staging; xác minh realtime, transaction tồn, session, email confirmation và idempotent retry.
5. Kiểm chứng barcode camera, OCR ảnh thực tế, voice và xuất/chia sẻ file trên thiết bị đích.
6. Chỉ cập nhật trạng thái user story khi toàn bộ acceptance criteria có bằng chứng; đóng gói/deploy khi được yêu cầu riêng.
