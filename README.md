<div align="center">

# 📦 Smart WMS — Inventory Assistant
### Hệ Thống Quản Lý Kho Hàng Thông Minh Đa Nền Tảng

[![Flutter](https://img.shields.io/badge/Flutter-3.47.0-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.7.0-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-BaaS-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Riverpod](https://img.shields.io/badge/State_Management-Riverpod_2.6-055399?style=for-the-badge&logo=flutter&logoColor=white)](https://riverpod.dev)

---

**Smart WMS** là giải pháp quản lý kho hàng thông minh đa nền tảng (Mobile App cho Thủ kho & Web Admin cho Quản lý), kết hợp công nghệ **Backend-as-a-Service (Supabase)**, **On-Device Computer Vision (ML Kit & Barcode Scanning)** và **AI Trợ lý ảo (LLM Edge Functions)** giúp tự động hóa quy trình nhập/xuất kho, giảm tỷ lệ sai sót xuống dưới **< 1%** và tăng tốc độ xử lý phiếu kho lên đến **80%**.

</div>

---

## 🚀 Các Tính Năng Nổi Bật (Key Features)

### 1. 📷 Batch Barcode / QR Scanning (Nhập/Xuất Hàng Loạt)
* **Quét mã siêu tốc**: Hỗ trợ giải mã liên tục các định dạng **EAN-13, EAN-8, Code128, QR Code** thông qua camera di động.
* **Tự động cộng dồn & Cảnh báo vượt mức**: Hệ thống tự động đếm số lượng, phát âm thanh feedback (BEEP / Haptic) và cảnh báo khi quét vượt số lượng dự kiến.

### 2. 🔍 OCR Text Recognition (Trích Xuất Hạn Sử Dụng & Số Lô)
* **On-Device OCR (ML Kit)**: Nhận diện trực tiếp ngày sản xuất (`EXP`/`HSD`) và số lô sản xuất (`LOT`/`Batch`) từ bao bì sản phẩm mà không cần kết nối mạng.
* **Tự động điền dữ liệu**: Khớp chính xác thông tin vào mẫu nhập kho, loại bỏ hoàn toàn việc thao tác bằng tay.

### 3. 🤖 Voice & Text AI Assistant (Trợ Lý Ảo Kho Hàng)
* **Xử lý Ngôn ngữ Tự nhiên (NLU)**: Phân tích câu lệnh giọng nói/văn bản (ví dụ: *"Kiểm tra tồn kho Mì Hảo Hảo ở kệ A1"*, *"Xuất 50 thùng Nước Aquafina cho đại lý X"*) thành intent và entity bằng **Supabase Edge Functions + LLM (Gemini 1.5 / GPT-4o-mini)**.
* **Tự động lập bản nháp phiếu**: Tự tạo phiếu xuất/nhập nháp với giao diện kiểm tra **Human-in-the-loop** trước khi lưu vào DB.

### 4. ⚡ Supabase Realtime & Web Admin Dashboard
* **Đồng bộ thời gian thực (< 500ms)**: Thay đổi tồn kho, trạng thái phiếu nhập/xuất được broadcast tức thì qua WebSocket Secure đến toàn bộ thiết bị.
* **Web Admin trực quan**: Biểu đồ thống kê biến động kho hàng (thông qua `fl_chart`), quản lý cây vị trí Sơ đồ kho (**Zone -> Rack -> Shelf -> Bin**), phân quyền người dùng (RBAC).

---

## 🏗️ Kiến Trúc Phần Mềm (Architecture)

Dự án áp dụng **Clean Architecture** kết hợp phương pháp tổ chức thư mục **Feature-First**:

```
lib/
├── app/                        # Cấu hình ứng dụng toàn cục
│   ├── router/                 # GoRouter routing (Declarative routing)
│   ├── theme/                  # Color Palette & Material 3 Dynamic Theme
│   └── app.dart                # MaterialApp.router configuration
├── bootstrap.dart              # Khởi tạo Supabase SDK, .env, Logger, Orientations
├── core/                       # Thành phần dùng chung (Core Utilities & Shared UI)
│   ├── constants/              # AppConstants, Supabase Tables & RPC Names
│   ├── enums/                  # UserRole, OrderType, OrderStatus
│   ├── errors/                 # Failures & Exceptions mapping
│   ├── extensions/             # Context & String Helper Extensions
│   ├── network/                # Supabase Client Provider & Network Info
│   ├── usecases/               # Base UseCase<Type, Params> Contract
│   ├── utils/                  # BarcodeParser, OcrTextExtractor, DateFormatter
│   └── widgets/                # Reusable Widgets (Loading, Error, ConfirmDialog)
├── features/                   # Các Module Chức Năng (Feature-First Clean Arch)
│   ├── ai_assistant/           # Module Trợ Lý AI
│   ├── auth/                   # Module Xác Thực & Phân Quyền
│   ├── inbound/                # Module Nhập Kho & OCR / Batch Scanning
│   ├── inventory/              # Module Tồn Kho & Sơ Đồ Kệ Hàng
│   └── outbound/               # Module Xuất Kho & Picklist
└── main.dart                   # Entry point ứng dụng
```

---

## 🛠️ Hướng Dẫn Cài Đặt & Khởi Chạy (Getting Started)

### 1. Yêu Cầu Tiên Quyết
* **Flutter SDK**: `>= 3.47.0` (Dart SDK `>= 3.7.0`)
* **Supabase CLI**: Đã cài đặt nếu bạn muốn deploy Edge Functions cục bộ.
* **Git**: Phiên bản mới nhất.

### 2. Clone Dự Án & Cài Đặt Dependencies
```bash
git clone https://github.com/nhon2511/InventoryAssistant.git
cd InventoryAssistant
flutter pub get
```

### 3. Cấu Hình Môi Trường (`.env`)
Tạo file `.env` tại thư mục gốc của dự án (tham khảo mẫu trong `.env.example`):
```env
SUPABASE_URL=https://your-supabase-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
```

### 4. Tạo Mã Nguồn Tự Động (Code Generation)
Dự án sử dụng **Riverpod Generator** cho State Management và dependency injection:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 5. Chạy Ứng Dụng (Run Application)
* **Mobile (Android/iOS)**:
  ```bash
  flutter run
  ```
* **Web Admin**:
  ```bash
  flutter run -d chrome
  ```

---

## 🧪 Testing & Static Analysis

Dự án duy trì tỷ lệ bao phủ kiểm thử cao cho các Business Logic UseCases và Helper Utilities:

```bash
# Chạy toàn bộ Unit Tests (26/26 tests passing)
flutter test

# Kiểm tra Linter / Static Code Analysis (0 Errors, 0 Warnings)
flutter analyze
```

---

## 🗄️ Supabase Backend & Database Schema

Hệ thống tận dụng tối đa tính năng của **Supabase PostgreSQL**:
* **Row Level Security (RLS)**: Phân quyền theo vai trò (`ADMIN`, `MANAGER`, `STAFF`).
* **Stored Procedures (RPC)**:
  * `confirm_inbound_order`: Tự động cộng tồn kho và ghi nhật ký giao dịch (`inventory_transactions`).
  * `confirm_outbound_order`: Kiểm tra số lượng tồn kho khả dụng (`quantity_on_hand`) và thực hiện trừ tồn kho an toàn bằng cơ chế khóa dòng (Locking).
* **Realtime Broadcast**: Lắng nghe sự thay đổi trên bảng `inventory_items` và `warehouse_orders`.
* **Edge Functions**:
  * `parse-intent`: Tiếp nhận câu thoại tiếng Việt, trích xuất Intent (`query_stock`, `create_order`) và Entities dưới dạng JSON.
  * `query-stock`: Thực hiện truy vấn tồn kho thông minh và sinh câu trả lời tự nhiên.
