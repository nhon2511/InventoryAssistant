# KẾ HOẠCH & PHÂN CÔNG FRONTEND — INVENTORY ASSISTANT (BẢN CẢI TIẾN V2)

> **Bản này gồm 2 phần:**
>
> - **Phần 1:** Đánh giá kế hoạch gốc dưới góc nhìn thiết kế full-stack.
> - **Phần 2:** Kế hoạch cải tiến, cấu trúc lại sâu hơn, có chuẩn bị sẵn cho giai đoạn tích hợp Backend/Supabase.

---

# PHẦN 1 — ĐÁNH GIÁ KẾ HOẠCH HIỆN TẠI

## 1.1. Điểm tốt

| Điểm | Nhận xét |
|---|---|
| Phân vai rõ ràng | Mỗi thành viên có mảng nghiệp vụ riêng (Thuận: layout/Dashboard, Vũ: Inventory, Khánh Hòa: Inbound/Outbound). Tránh chồng lấn file. |
| Chia tuần theo độ khó tăng dần | Tuần 1 dựng khung → Tuần 2 luồng nghiệp vụ → Tuần 3 camera/OCR → Tuần 4 AI + tổng kết. Đây là thứ tự hợp lý. |
| Mock-data-first | Ưu tiên UI và luồng tương tác trước, không chờ backend. Đúng hướng cho đồ án/sprint ngắn. |
| Có yêu cầu PR review | Mỗi task commit + tạo Pull Request để review — nền tảng tốt cho làm việc nhóm. |
| Yêu cầu OCR có bước "người dùng kiểm tra" | Không tự động lưu kết quả OCR — quyết định UX đúng, tránh dữ liệu sai vào kho. |

## 1.2. Điểm thiếu / rủi ro (theo mức độ nghiêm trọng)

### A. Rủi ro cao — ảnh hưởng trực tiếp đến giai đoạn tích hợp backend

1. **Chưa có data model và API contract.**
   Tài liệu liệt kê màn hình nhưng không định nghĩa `Product`, `Batch`, `Location`, `InboundOrder`, `OutboundOrder`, enum trạng thái phiếu. Đây là rủi ro lớn nhất: nếu mỗi người tự định nghĩa model trong mock data, khi nối Supabase sẽ phải sửa lại toàn bộ UI và thống nhất lại từ đầu. **Phải chốt model + contract ở Tuần 0.**

2. **Mock data rời rạc, không có lớp Repository.**
   Kế hoạch nói "dùng mock data" nhưng không nói mock ở đâu. Nếu mock nằm trực tiếp trong widget, sau này thay bằng API thật sẽ phải đụng vào từng màn hình. Cần một lớp **Repository interface** (ví dụ `ProductRepository`, `InboundRepository`) với 2 implementation: `MockRepository` (giai đoạn này) và `SupabaseRepository` (giai đoạn sau). UI chỉ phụ thuộc interface → chuyển backend không đổi UI.

3. **Chưa chọn state management và kiến trúc thư mục.**
   Không có quyết định Riverpod/Bloc/GetX và không có cấu trúc thư mục chuẩn. Với 3 người code song song trong 4 tuần, thiếu 2 thứ này gần như chắc chắn dẫn đến xung đột và code lặp.

### B. Rủi ro trung bình — ảnh hưởng chất lượng và tiến độ

4. **Khối "Cả nhóm" ở Tuần 3–4 quá rộng.** Barcode/QR, OCR, AI Assistant đều giao cho "cả nhóm" mà không có người phụ trách chính từng mảng → dễ bỏ sót, khó review. Cần gán owner cụ thể.

5. **Quy trình Git còn chung chung.** Thiếu: convention đặt tên nhánh, commit message, giới hạn kích thước PR, tiêu chí approve, và **Definition of Done** cho mỗi task.

6. **Thiếu design token/theme trước khi làm component.** Tuần 1 làm ngay 12+ component mà chưa chốt màu trạng thái (Còn hàng / Sắp hết / Hết hàng / Sắp hết hạn), spacing, typography → Tuần 2 "thống nhất UI" sẽ thành sửa lại toàn bộ.

7. **Không có chiến lược test tối thiểu.** Form nhập/xuất có nhiều validation — đây là chỗ nên có widget test. Ít nhất nên test các rule: số lượng > 0, xuất không vượt tồn, EXP hợp lệ.

### C. Rủi ro cần kiểm chứng sớm (spike)

8. **Camera/OCR là rủi ro kỹ thuật lớn nhất** nhưng bị xếp vào Tuần 3. Camera trên emulator thường không hoạt động như máy thật; OCR tiếng Việt và nhận diện định dạng LOT/EXP cần thử sớm. Nên có **spike nhỏ ngay Tuần 1** (mở được camera, quét được 1 mã, chạy được ML Kit trên máy thật) để nếu trục trặc còn 2 tuần xoay sở.

9. **Hiệu năng danh sách lớn** (Inventory vài nghìn dòng) chưa được nhắc: cần `ListView.builder`/pagination ngay từ đầu, không phải sửa sau.

10. **AI Assistant chưa ràng buộc đầu vào/đầu ra.** Mục "AI trả về JSON" là hướng đúng, nhưng cần định nghĩa schema đầy đủ cho mọi loại kết quả (text, tồn kho, draft inbound/outbound) ngay từ Tuần 0 để UI chat hiển thị đúng.

## 1.3. Kết luận đánh giá

Kế hoạch gốc **tốt về phân công và nhịp tuần**, nhưng **thiếu tầng nền (foundation)**: kiến trúc, data model, repository, design token, quy trình Git. Nếu bổ sung một "Tuần 0 — Foundation" (3–4 ngày, cả nhóm cùng làm), 4 tuần sau sẽ đi nhanh hơn hẳn và giai đoạn tích hợp backend gần như không phải viết lại UI.

---

# PHẦN 2 — KẾ HOẠCH CẢI TIẾN

## PHÂN CÔNG (giữ nguyên vai trò chính, bổ sung owner cho khối chung)

| Thành viên | Nhiệm vụ chính | Phụ trách thêm ở Tuần 3–4 |
|---|---|---|
| **Thuận** | Layout, Navigation, Dashboard, UI Components, Theme | Owner: AI Assistant UI |
| **Vũ** | Inventory, Product, Batch/LOT | Owner: OCR |
| **Khánh Hòa** | Inbound, Outbound, Form nghiệp vụ | Owner: Barcode/QR Scanner |
| **Cả nhóm** | Review chéo, Integration, Final Review | — |

> Nguyên tắc: mỗi task có **1 owner duy nhất**. Người khác hỗ trợ qua review PR. Mọi PR cần ít nhất 1 approve từ thành viên không phải owner.

---

## TUẦN 0 — FOUNDATION (MỚI, 3–4 ngày, cả nhóm)

### Mục tiêu

Chốt toàn bộ quyết định kiến trúc trước khi viết màn hình. Không merge màn hình nghiệp vụ nào trong tuần này.

### 0.1. Kiến trúc thư mục (feature-first)

```text
lib/
  main.dart
  core/
    theme/            # design token: màu, spacing, typography
    router/           # go_router: route table, navigation guard
    utils/
  shared/
    widgets/          # component dùng chung (AppButton, AppTextField, ...)
    models/           # Product, Batch, Location, InboundOrder, ...
  features/
    dashboard/
      view/           # màn hình
      controller/     # state (Riverpod provider / Bloc)
      repository/     # interface + mock impl
    inventory/
    inbound/
    outbound/
    ai_assistant/
```

- **State management:** chọn **một** — khuyến nghị **Riverpod** (nhẹ, dễ test, phù hợp quy mô này). Ghi quyết định vào README, không ai dùng `setState` cho dữ liệu nghiệp vụ.
- **Routing:** `go_router`, khai báo tập trung trong `core/router`.

### 0.2. Design token & Theme

Chốt trước khi làm component:

| Token | Quy ước |
|---|---|
| Màu trạng thái tồn kho | Còn hàng (xanh), Sắp hết (vàng/cam), Hết hàng (đỏ) |
| Màu cảnh báo hạn dùng | Sắp hết hạn < 30 ngày (cam), Hết hạn (đỏ) |
| Màu trạng thái phiếu | Draft (xám), Pending (vàng), Confirmed (xanh dương), Completed (xanh lá) |
| Spacing | Thang 4/8/12/16/24 |
| Typography | 1 font chính, thang cỡ chữ cố định |
| Component size | Chiều cao button, textfield tối thiểu 44–48 (touch target) |

Định nghĩa trong `core/theme/app_theme.dart`, cấm hard-code màu trong widget.

### 0.3. Data model & API contract

Cả nhóm cùng chốt model trong `shared/models/` — đây là "hợp đồng" giữa frontend và backend sau này:

```text
Product       : id, sku, barcode, name, unit, imageUrl, minStock
Batch         : id, productId, lotCode, expiryDate, quantity, locationId
Location      : id, code, name
InboundOrder  : id, code, status(draft|pending|confirmed|completed),
                items: [{ productId, batchId, quantity, expiryDate, locationId }],
                createdAt, createdBy
OutboundOrder : id, code, status(...), items: [...], note
StockView     : productId, totalQty, byBatch[], byLocation[]   # view tổng hợp
AiResult      : type(text|stock_info|draft_inbound|draft_outbound), payload
```

Quy ước: tên field **snake_case** (giống Supabase) hoặc camelCase + `fromJson/toJson` chuẩn — chọn 1, ghi vào README.

### 0.4. Lớp Repository

```text
features/inventory/repository/
  product_repository.dart        # abstract class ProductRepository
  mock_product_repository.dart   # MockProductRepository (dữ liệu giả, delay 300ms)
```

- UI/controller chỉ gọi interface, **cấm import mock impl** vào widget.
- Mock impl trả về `Future` có delay để test được Loading state thật.
- Mock data tập trung trong một file `mock_data.dart` dùng chung (ít nhất: 20 sản phẩm, có đủ 3 trạng thái tồn, có batch sắp hết hạn) để mọi màn hình nhất quán.

### 0.5. Quy ước Git & Definition of Done

- **Nhánh:** `feature/<ten-tinh-nang>` (ví dụ `feature/inventory-list`), merge vào `dev`, `main` chỉ nhận từ `dev` khi chốt tuần.
- **Commit:** Conventional Commits — `feat:`, `fix:`, `refactor:`, `style:`, `docs:`.
- **PR:** nhỏ gọn (dưới ~400 dòng diff), có mô tả + ảnh chụp màn hình, 1 approve mới được merge.
- **Definition of Done cho mọi task UI:**
  - [ ] Đủ các trạng thái: Loading / Empty / Error / Success.
  - [ ] Không hard-code màu, text, spacing (dùng theme).
  - [ ] Dùng component chung, không viết lại.
  - [ ] Dữ liệu đi qua Repository, không mock trong widget.
  - [ ] `flutter analyze` không còn warning mới.
  - [ ] Có ảnh/video demo trong PR.
- **CI:** GitHub Actions chạy `flutter analyze` (+ test nếu có) trên mỗi PR.

**Đầu ra Tuần 0:** repo có khung thư mục, theme, router rỗng, models, repository interface + mock, CI chạy xanh.

---

## TUẦN 1 — KHUNG ỨNG DỤNG & UI COMPONENTS

### Mục tiêu

Như kế hoạch gốc, cộng thêm: mọi màn hình dựng đã gắn vào router và repository mock thật.

### 1. Layout & Navigation — Thuận

- App Shell: AppBar/Header, Sidebar (desktop/tablet), Bottom Navigation (mobile) — dùng `NavigationRail`/`NavigationBar` với `go_router` ShellRoute.
- Menu: Dashboard, Inventory, Inbound, Outbound, AI Assistant, (Profile/Settings nếu có).
- Highlight màn hình hiện tại trên navigation theo route.
- **DoD bổ sung:** đổi kích thước màn hình không vỡ layout (responsive breakpoint rõ: <600 mobile, ≥600 tablet/desktop).

### 2. UI Components — Thuận

Danh sách như kế hoạch gốc (Button, TextField, Dropdown, SearchBar, Card, DataTable/List, Dialog, BottomSheet, Snackbar, Loading, EmptyState, ErrorState, ConfirmDialog), **cộng thêm:**

- `StatusChip` (trạng thái tồn kho / trạng thái phiếu — dùng màu token Tuần 0).
- `QuantityBadge`, `ExpiryWarningChip`.
- Một trang **Widget Gallery** nội bộ (route ẩn `/dev/widgets`) liệt kê mọi component với các trạng thái — làm chuẩn để review và test.

### 3. Dashboard — Thuận

Như kế hoạch gốc (card tổng quan, biểu đồ nhập/xuất, recent activities), dữ liệu lấy qua `DashboardRepository` mock. Biểu đồ: `fl_chart`.

### 4. Inventory — Vũ

Như kế hoạch gốc (list + search/filter/sort + trạng thái + product detail), **cộng thêm:**

- Danh sách dùng `ListView.builder` (chuẩn bị cho dữ liệu lớn).
- Detail là **route riêng** (`/inventory/:id`), không chỉ popup, để sau này deep-link từ scanner/AI.

### 5. Inbound & 6. Outbound — Khánh Hòa

Như kế hoạch gốc (danh sách phiếu, form tạo, trạng thái Draft/Pending/Confirmed/Completed), **cộng thêm:**

- Form field cho Batch/EXP dùng component chung, để Tuần 3 gắn scanner/OCR vào mà không sửa layout.
- Item trong phiếu có swipe-to-delete hoặc nút xóa rõ ràng.

### 7. Spike kỹ thuật (MỚI — 1 ngày, Khánh Hòa + Vũ)

- Chạy được `mobile_scanner` (hoặc lib tương đương) trên **máy thật**, quét 1 mã bất kỳ, in kết quả.
- Chạy được ML Kit OCR trên máy thật, nhận diện 1 dòng text trên bao bì thật.
- Ghi kết quả + ảnh chụp vào `docs/spike-scanner-ocr.md`. Nếu trục trặc → đổi thư viện ngay tuần này, không đợi Tuần 3.

---

## TUẦN 2 — HOÀN THIỆN LUỒNG NGHIỆP VỤ

### Mục tiêu

Như kế hoạch gốc: mọi màn hình thao tác hoàn chỉnh bằng mock data qua Repository.

### 1. Inventory — Vũ

Như kế hoạch gốc. **Bổ sung:** skeleton loading (thay vì chỉ spinner), pull-to-refresh, giữ vị trí scroll khi quay lại từ detail.

### 2. Inbound & 3. Outbound — Khánh Hòa

Flow và validation như kế hoạch gốc. **Bổ sung:**

- Validation gom thành **unit-testable** (hàm thuần trong `controller/` hoặc `core/utils/validators.dart`) và có **widget test** cho 3 rule quan trọng: số lượng > 0, xuất không vượt tồn, EXP hợp lệ.
- Confirm phiếu → cập nhật mock repository (tồn kho thay đổi thật trong session) để Dashboard/Inventory phản ánh được — kiểm chứng luồng xuyên màn hình.

### 4. Dashboard — Thuận

Như kế hoạch gốc. Card "Sản phẩm sắp hết/hết hàng" nhấn vào điều hướng sang Inventory với filter tương ứng.

### 5. UI/UX Review — Cả nhóm

Checklist như kế hoạch gốc, chấm theo **Widget Gallery** và design token đã chốt (không cãi nhau theo cảm tính — lệch token là bug).

---

## TUẦN 3 — BARCODE/QR & OCR

### Mục tiêu

Như kế hoạch gốc. Spike Tuần 1 đã giảm rủi ro thư viện.

### 1. Barcode / QR — Owner: Khánh Hòa

Như kế hoạch gốc (scanner screen, xử lý mã hợp lệ/không tồn tại/trùng/thất bại, scan lại, gắn vào form Inbound/Outbound). **Bổ sung:**

- Scanner là component dùng chung (`shared/widgets/`) nhận callback `onResult` — form nào cũng gắn được.
- Tra cứu sản phẩm qua `ProductRepository.findByBarcode()`, không đọc mock trực tiếp.

### 2. OCR — Owner: Vũ

Flow như kế hoạch gốc (Camera/Image → OCR → người dùng kiểm tra → điền vào form; không tự lưu; cho sửa; có trạng thái đang nhận diện; xử lý không nhận diện được). **Bổ sung:**

- Kết quả OCR trả về dạng có cấu trúc `{ lotCode?, expiryDate? }` kèm **độ tin cậy**; field nào độ tin cậy thấp thì highlight cho người dùng kiểm tra.
- Gom parse LOT/EXP thành hàm thuần có unit test (nhiều định dạng ngày: `EXP 12/2026`, `HSD: 2026-12-31`...).

### 3. Inventory UI — Vũ

Như kế hoạch gốc (filter theo Batch/EXP/Location, cảnh báo sắp hết hạn). Dùng `ExpiryWarningChip` đã có.

### 4. Tích hợp form — Khánh Hòa

Như kế hoạch gốc: gắn scanner/OCR vào form Inbound/Outbound, không phá layout (nhờ đã chừa chỗ ở Tuần 1).

---

## TUẦN 4 — AI ASSISTANT UI & HOÀN THIỆN

### 1. AI Assistant UI — Owner: Thuận

Như kế hoạch gốc (chat list, bubble, typing indicator, input, send, clear chat). **Bổ sung:**

- Message renderer theo `AiResult.type` đã định nghĩa ở Tuần 0: text thuần, card tồn kho, card draft phiếu.
- Mock AI bằng `AiAssistantRepository` trả kết quả giả theo từ khóa (ví dụ chứa "lấy"/"xuất" → draft outbound) để demo được flow mà không cần backend.

### 2. AI tạo Draft — Cả nhóm (Thuận ghép UI, Khánh Hòa kiểm chứng nghiệp vụ)

Như kế hoạch gốc: hiển thị Draft Inbound/Outbound với nút Xác nhận / Hủy / Chỉnh sửa. **Bổ sung:** nhấn Xác nhận → điều hướng sang form Outbound/Inbound đã điền sẵn (prefill), không tự confirm — người dùng vẫn là người confirm cuối.

### 3. Frontend Integration — Cả nhóm

Checklist luồng như kế hoạch gốc, cộng thêm: Scanner → Inventory detail, AI → prefill form, Inbound confirm → tồn kho/Dashboard cập nhật.

### 4. UI State & 5. Final Review — Cả nhóm

Như kế hoạch gốc (loading/success/empty/error/confirmation/validation; `flutter analyze`; review code), **cộng thêm:**

- Chạy widget test và sửa test hỏng.
- Demo end-to-end trên máy thật, quay video.
- **Chốt hồ sơ bàn giao tích hợp** (mục dưới).

---

## CHUẨN BỊ TÍCH HỢP BACKEND (SUPABASE) — HỒ SƠ BÀN GIAO

Đây là phần mới, hoàn thành trong Tuần 4, là điều kiện đóng giai đoạn frontend.

### 1. Cơ chế chuyển đổi

```text
UI/Controller ──► Repository interface ──► MockProductRepository      (giai đoạn này)
                                        └► SupabaseProductRepository  (giai đoạn sau)
```

Khi tích hợp: viết `SupabaseXxxRepository` implement đúng interface, đổi 1 dòng ở chỗ "đăng ký provider" — **UI không đổi**.

### 2. Danh sách bảng/endpoint dự kiến (từ data model Tuần 0)

| Bảng Supabase | Nguồn model | Ghi chú |
|---|---|---|
| `products` | Product | unique trên `sku`, `barcode` |
| `batches` | Batch | FK `product_id`, FK `location_id` |
| `locations` | Location | |
| `inbound_orders` + `inbound_items` | InboundOrder | trigger cập nhật tồn khi confirm |
| `outbound_orders` + `outbound_items` | OutboundOrder | kiểm tra tồn ở server khi confirm |
| `stock_view` | StockView | view tổng hợp từ batches |

### 3. Checklist sẵn sàng tích hợp

- [ ] Mọi màn hình lấy dữ liệu qua Repository interface (không còn mock trong widget).
- [ ] Model có `fromJson/toJson` khớp tên cột Supabase.
- [ ] Enum trạng thái phiếu map 1-1 với giá trị lưu ở DB.
- [ ] Có sẵn file ghi mapping field frontend ↔ backend (`docs/api-contract.md`).
- [ ] Auth: đã phân tách `AuthRepository` (mock login) để sau thay bằng Supabase Auth.

---

## QUẢN LÝ RỦI RO & PHỤ THUỘC

| Rủi ro | Ảnh hưởng | Cách xử lý |
|---|---|---|
| Camera không chạy tốt trên emulator/thiết bị | Trễ Tuần 3 | Spike Tuần 1; yêu cầu test trên máy thật; fallback nhập tay luôn có sẵn |
| OCR nhận diện kém (tiếng Việt, định dạng LOT/EXP lạ) | Sai dữ liệu | Luôn có bước người dùng kiểm tra; parse là hàm thuần có test; ghi nhận định dạng thật từ bao bì mẫu |
| AI chưa có backend thật | Demo Tuần 4 kém thuyết phục | Mock theo schema `AiResult`; ràng buộc bằng kịch bản demo cố định |
| Một thành viên trễ task | Dây chuyền | Owner phụ trách chéo ở Tuần 3–4 có thể đổi; component chung và contract Tuần 0 giảm phụ thuộc lẫn nhau |
| Xung đột code khi 3 người cùng sửa | Mất thời gian merge | Kiến trúc feature-first: mỗi người một thư mục feature; code chung chỉ sửa qua PR review kỹ |

## PHỤ THUỘC GIỮA CÁC THÀNH VIÊN

- Thuận xong **Theme + 5 component lõi** (Button, TextField, Card, Loading, EmptyState) trước giữa Tuần 1 → Vũ và Khánh Hòa dùng ngay.
- Cả nhóm xong **model + repository interface** trong Tuần 0 → mọi task Tuần 1+ phụ thuộc vào đây.
- Scanner/OCR (Tuần 3) phụ thuộc form Tuần 1–2 đã chừa chỗ — nếu form trễ, gắn scanner vào màn demo riêng trước.

---

## TÓM TẮT THAY ĐỔI SO VỚI KẾ HOẠCH GỐC

1. Thêm **Tuần 0 — Foundation**: kiến trúc, theme, model/contract, repository, Git/DoD, CI.
2. Mock data đi qua **Repository interface**, không hard-code trong UI.
3. Khối "Cả nhóm" Tuần 3–4 được gán **owner cụ thể**.
4. Thêm **spike camera/OCR ở Tuần 1** để giảm rủi ro Tuần 3.
5. Thêm **widget test tối thiểu** cho validation nghiệp vụ.
6. Thêm mục **chuẩn bị tích hợp Supabase** với checklist bàn giao.
7. Thêm bảng **rủi ro và phụ thuộc** giữa các thành viên.
