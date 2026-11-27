# CP8 — Nghiệm thu Android và Web Smart WMS

Ngày 27/11/2026. Branch `feature/backend-phase1-rest-apis`. Bản kiểm tra này phân biệt mã/test offline, Web preview trong browser thật, Android device và PostgreSQL/Supabase thật. Không kết nối DB, không chạy `test:db`, migration, seed hoặc deploy.

## Trạng thái Git và quality gates

Trước CP8: tracked tree và staged diff sạch; chỉ `docs/KE_HOACH_KIEN_TRUC_TYPESCRIPT_BACKEND_SMART_WMS.md` và toàn bộ `supabase/` untracked. Branch theo `origin/feature/backend-phase1-rest-apis`, ahead/behind `0/0`. CP2–CP7 có trong lịch sử local và upstream, từ `ae8d109` đến `b95f51c`. Không fetch, merge hoặc push `main`.

| Gate | Kết quả mới nhất | Giới hạn |
|---|---|---|
| `flutter analyze --no-pub` | PASS, 0 issue | Static analysis |
| `flutter test --no-pub` | PASS, 154/154 | Mock/fixture, không kết nối backend thật |
| `flutter build web --no-pub` | PASS, Web JavaScript | Wasm dry-run cảnh báo từ `image-4.3.0`; không xác nhận Wasm |
| `flutter build apk --debug` | PASS | Plugin Kotlin Gradle có cảnh báo tương thích Flutter tương lai; không chứng minh chạy trên Android device |
| `npm run prisma:validate` / `prisma:generate` | PASS / PASS | URL giả cho schema tooling; không kết nối DB |
| `npm test` / `npm run test:e2e` | PASS 179/179 / PASS 17/17 | Offline/mocked E2E; log 401/403/404 là case được test |
| `npm run lint` / `npm run build` | PASS / PASS | Backend TypeScript |
| `git diff --check` | PASS | Kiểm tra whitespace |
| `test:db` và migration | NOT RUN | Không có test target được duyệt |

## Nghiệm thu trực tiếp theo nền tảng

**Web browser:** Bản `lib/main_preview.dart` chạy tại `localhost` trong Chromium in-app browser, viewport khoảng 718×625 và 1280×720. Đã thao tác login Admin, logout, login STAFF, xem khác biệt vai trò, dashboard và refresh, mở báo cáo và lọc từ ngày, mở form nhập nhiều dòng và thấy validation thiếu sản phẩm/vị trí/số lượng, xem danh mục STAFF không có nút tạo. Sau sửa, dashboard hiện nhãn **Dữ liệu mẫu** đúng với fixture. Bộ quét nhận mã nhập tay và tăng bộ đếm; nút bật camera không tạo feed có thể xác minh. Micro chuyển UI sang “Đang lắng nghe” rồi dừng được, nhưng chưa kiểm tra transcript tiếng nói. Đây là **browser thật với fixture bộ nhớ**, không phải Web production hoặc dữ liệu NestJS/Supabase thật. Playwright Chrome extension không có nên dùng browser in-app. PDF preview trong browser nhúng không mở; sau CP8 timeout 30 giây đã thấy UI thoát trạng thái bận và báo lỗi. Đã bấm xuất Excel nhưng chưa xác nhận artifact được tải/chia sẻ; chưa kiểm tra Chrome/Edge ngoài browser nhúng.

**Android:** `flutter devices` không phát hiện Android device/emulator; chỉ có Windows, Chrome và Edge. APK debug build PASS. Không có kiểm tra camera, micro, quyền OS, share hoặc workflow Android thực.

**PostgreSQL/Supabase:** Cả bảy tên biến `DATABASE_TEST_URL`, `DATABASE_TEST_BACKEND_URL`, `DATABASE_TEST_PROJECT_REF`, `DATABASE_DEV_PROJECT_REF`, `DATABASE_TEST_ALLOWED_REFS`, `DATABASE_TEST_ACTOR_ID`, `DATABASE_TEST_APPROVED` đều vắng. Không đọc giá trị URL/key/password, không fallback sang `DATABASE_URL`/`DIRECT_URL`, không kết nối DB. CP5 inventory/ledger/idempotency/rollback và schema/role/RLS vẫn chưa có integration evidence.

## User stories: mức bằng chứng

“Offline” là mã + test mock/fixture; “Web preview” là thao tác trong browser với fixture; “DB thật” đòi test target an toàn. Không hàng nào được coi hoàn thành end-to-end production.

| US | Offline | Web preview trực tiếp | Android device | DB thật | Chưa đạt / blocker |
|---|---|---|---|---|---|
| 01 Login | Có: auth/UI tests | Login/logout fixture | Chưa | Chưa | Supabase Auth session thật và profile cần target test |
| 02 Role | Có: UI + backend guard tests | STAFF không có tạo sản phẩm | Chưa | Chưa | Đối chiếu JWT role, profile và quyền server trên target |
| 03 Batch barcode | Có: session/manual/debounce tests | Nhập tay tăng bộ đếm fixture; camera không có feed xác minh | Chưa | Không áp dụng riêng | Camera/permission và nhiều mã liên tiếp chưa kiểm tra thật |
| 04 OCR LOT/HSD | Có: parser, Web service/widget tests | Chưa thử ảnh/camera thật | Chưa | Chưa | Android chỉ nhập tay; LOT/HSD sau duyệt chưa persist qua confirm API |
| 05 Phiếu nhập | Có: draft/review/confirm mock tests | Form và validation fixture | Chưa | Chưa | Schema, inventory row, role/ledger/idempotency transaction thật |
| 06 Tra tồn | Có: Nest adapter + UI tests | Catalog/dashboard fixture | Chưa | Chưa | API/JWT/stock trên project test |
| 07 Vị trí hàng | Có: catalog/stock tests | Chưa drilldown vị trí | Chưa | Chưa | API và dữ liệu location/inventory thật |
| 08 Tồn thấp | Có: tính theo sản phẩm/đơn vị | Dashboard fixture | Chưa | Chưa | Snapshot thật và ngưỡng nghiệp vụ |
| 09 Pick list | Có: order line/detail + UI tests | Chưa chạy picking thật | Chưa | Chưa | API order detail, vị trí và sản phẩm thật |
| 10 Quét đối soát xuất | Có: barcode đúng/sai/cap/undo/reset | Chưa thử camera thật | Chưa | Chưa | Camera, phiếu CONFIRMED thật và confirm integration |
| 11 Trừ tồn khi xuất | Có: transaction/service mock tests | Chưa | Chưa | Chưa | CP5 PostgreSQL test + ledger/rollback/concurrency |
| 12 AI hỏi tồn | UI lỗi trung thực; không có kết quả production | Chưa | Chưa | Chưa | Edge Function source/deploy/JWT/contract chưa xác minh; fail-closed |
| 13 AI draft | Preview/gate mock tests | Chưa | Chưa | Chưa | Edge Function và mapping duy nhất product/location; không tự lưu |
| 14 Voice | Test text chờ bấm Gửi | UI listening/stop, chưa có transcript | Chưa | Không áp dụng riêng | Thiết bị/browser permission và nhận dạng tiếng Việt thật |
| 15 Realtime | Stream mock payload/unsubscribe | Dashboard refresh thủ công | Chưa | Chưa | Publication/RLS/event NestJS → Supabase Realtime chưa xác minh |
| 16 Quản lý vị trí | CRUD adapter/UI role tests | Chưa thao tác trực tiếp | Chưa | Chưa | Quyền và ràng buộc dữ liệu thật |
| 17 Báo cáo | Snapshot/order/filter/Excel/PDF offline tests | Lọc ngày fixture; PDF browser nhúng lỗi có timeout; Excel artifact chưa xác nhận | Chưa | Chưa | Export trên Chrome/Android thật; chưa có ledger contract báo cáo theo kỳ |

## Kịch bản demo không dùng secret

1. Chạy `flutter run -d chrome -t lib/main_preview.dart`. Đăng nhập `admin@preview.local`, `manager@preview.local` hoặc `staff@preview.local` với chuỗi bất kỳ không rỗng. Giải thích nhãn **Dữ liệu mẫu** trước khi thao tác.
2. Xem dashboard theo đơn vị, bấm tải lại; tra catalog và vị trí; so sánh STAFF với Admin. Tạo form nhập nhiều dòng, thử validation số lượng và quét mã nhập tay. Không giới thiệu fixture là stock production.
3. Mở phiếu đã duyệt trong preview, nhập số lượng thực tế, thử quá giới hạn, undo/reset scan; chỉ nhấn confirm khi có test target đã phê duyệt trong một buổi nghiệm thu riêng.
4. Xem báo cáo tồn hiện tại và lọc ngày tạo phiếu; thử Excel/PDF trên browser/thiết bị hỗ trợ. Nêu rõ thiếu ledger báo cáo theo kỳ. AI production hiện trả lỗi chưa khả dụng; voice chỉ điền text. OCR LOT/HSD sau duyệt là preview, chưa lưu qua confirm.

## Điều kiện gỡ blocker

- Owner cung cấp project test disposable khác Dev, đủ bảy biến guard, canonical schema/role/unique inventory row được duyệt và kế hoạch reset; chạy preflight B7 riêng trước mọi integration test ghi fixture.
- Dùng Android device và Chrome/Edge trên HTTPS hoặc localhost với quyền camera/micro; thử barcode đúng/sai/lặp, OCR Web, voice, PDF/Excel/share và lỗi permission.
- Xác minh NestJS JWT/role, CORS và end-to-end order → stock → ledger trên test target; thử lỗi mạng, session hết hạn và hai request đồng thời.
- Review source/deployment Edge Function và publication/RLS Realtime; sau đó mới bật đường AI/realtime production. Bổ sung contract cập nhật LOT/HSD nếu yêu cầu lưu sau duyệt.
