# BÁO CÁO KỸ THUẬT: TASK-DB-03 — SUPABASE POSTGRESQL CONNECTION & SCHEMA AUDIT

- **Dự án**: InventoryAssistant — Smart Warehouse Management System
- **Hệ thống**: Backend (NestJS 12, TypeScript, Prisma 6.19.3) & Database (Supabase PostgreSQL 17.6)
- **Nhánh Git**: `feature/backend-nestjs-init`
- **Ngày thực hiện**: 12/11/2026
- **Quyền hạn phê duyệt**: Project Owner Limited Approval (READ-ONLY Scope)
- **Kỹ sư phụ trách**: Senior NestJS & Supabase Database Architect / QA Lead

---

## 1. TỔNG QUAN ĐIỀU HÀNH (EXECUTIVE SUMMARY)

Thực hiện theo phê duyệt giới hạn của Project Owner, giai đoạn **TASK-DB-03 Phase 2** đã hoàn tất với kết quả mỹ mãn trong phạm vi **READ-ONLY 100%**:
1. **Kiểm thử kết nối (Smoke Test)**: Kết nối thành công tới Supabase Cloud PostgreSQL 17 qua Shared Session Pooler (cổng 5432, IPv4) trong thời gian **1873ms**. Lệnh truy vấn kiểm tra `SELECT 1;` thành công dưới phiên làm việc cưỡng chế `default_transaction_read_only = ON` và `statement_timeout = 10000ms`.
2. **Khớp nối dự án (Target Match)**: Project Reference ID khớp hoàn toàn giữa cấu hình Flutter và cấu hình Backend.
3. **Hiện trạng Database thực tế**: Schema `public` hiện có **7 bảng** (`profiles`, `products`, `locations`, `inventory_items`, `warehouse_orders`, `warehouse_order_items`, `your_table`). Không có native PostgreSQL enums.
4. **Đối chiếu Schema Prisma vs PostgreSQL**:
   - **1 Model MATCHED**: `Product`.
   - **1 Model MINOR MISMATCH**: `WarehouseOrderItem` (kiểu `expiry_date` trong DB là `date`, Prisma khai báo `String?`).
   - **4 Models CONFLICTED**: `Profile`, `Location`, `InventoryItem`, `WarehouseOrder`.
   - **2 Models MISSING**: `StockLedger`, `IdempotencyKey`.
   - **1 Bảng thừa (Orphan Table)**: `your_table`.
5. **Phát hiện quan trọng bảo vệ Frontend Flutter**: Cấu hình PostgreSQL hiện tại đang phục vụ chính xác các DTO Data Models của Flutter (`zone_code`, `phone_number`, `max_capacity_kg`, v.v.). Mọi hành động chạy `prisma db push` sẽ gây breaking-change phá hủy Flutter app. Chiến lược chuẩn xác là điều chỉnh `schema.prisma` ở Backend để khớp với PostgreSQL thực tế.

---

## 2. KẾT QUẢ KIỂM THỬ KẾT NỐI (CONNECTION TEST DETAILS)

| Thuộc tính kiểm tra | Kết quả ghi nhận | Đánh giá |
| :--- | :--- | :--- |
| **Trạng thái kết nối** | **PASS** (1873ms) | Kết nối ổn định qua Supabase Shared Session Pooler |
| **Host / Pooler Type** | `aws-0-*.pooler.supabase.com` | Session Mode (Port 5432 IPv4) |
| **PostgreSQL Version** | **PostgreSQL 17.6** | Bản phân phối chính thức mới nhất của Supabase |
| **TLS/SSL Encryption** | **VERIFIED (`sslmode=require`)** | Mã hóa TLS đầu cuối bắt buộc |
| **Database & User** | Database: `postgres`, User: `postgres` | Tài khoản quản trị dự án Development |
| **Session Safety Constraints** | `default_transaction_read_only = ON`<br>`statement_timeout = 10000ms` | Đảm bảo không phát sinh bất kỳ thay đổi dữ liệu nào |
| **Probe Query** | `SELECT 1 as probe;` -> `[{ probe: 1 }]` | **PASS** |

---

## 3. DANH SÁCH BẢNG HIỆN HỮU TRONG POSTGRESQL (PUBLIC SCHEMA)

Qua trích xuất danh mục hệ thống `information_schema.tables`, hiện diện 7 bảng:

1. `profiles`: Bảng hồ sơ nhân sự kho (liên kết với Supabase Auth).
2. `products`: Bảng danh mục sản phẩm / hàng hóa.
3. `locations`: Bảng vị trí lưu kho (khu vực, dãy, kệ, ô chứa).
4. `inventory_items`: Bảng tồn kho chi tiết tại từng vị trí.
5. `warehouse_orders`: Bảng phiếu lệnh kho (Inbound / Outbound).
6. `warehouse_order_items`: Bảng chi tiết mặt hàng trong phiếu lệnh.
7. `your_table`: Bảng starter mẫu của Supabase (chứa cột `id bigint`, `created_at timestamptz`).

---

## 4. MA TRẬN ĐỐI CHIẾU PRISMA VS POSTGRESQL (SCHEMA MISMATCH MATRIX)

| Prisma Model | Bảng PostgreSQL | Trạng thái | Chi tiết sai lệch (Mismatch Details) |
| :--- | :--- | :---: | :--- |
| **Product** | `products` | **MATCHED** | Cấu trúc bảng, cột, khóa chính, và các chỉ mục unique (`sku`, `barcode`) khớp 100%. Sai khác nhỏ: giá trị mặc định của `unit` trong DB là `'Pcs'` còn Prisma là `'Cái'`. |
| **WarehouseOrderItem** | `warehouse_order_items` | **MINOR_MISMATCH** | Cấu trúc cột, foreign keys (`order_id`, `product_id`, `location_id`) khớp hoàn toàn. Khác biệt: cột `expiry_date` trong DB là kiểu `date`, trong khi Prisma đang khai báo kiểu `String?`. |
| **Profile** | `profiles` | **CONFLICTED** | 1. **Thiếu cột**: Trong DB **không có cột `email`** (email nằm ở `auth.users`); Prisma đang khai báo `email String @unique`.<br>2. **Thừa cột**: Trong DB có `phone_number text`, Prisma chưa khai báo.<br>3. **Nullability**: `full_name` trong DB là `NOT NULL`, Prisma là optional (`String?`).<br>4. **Kiểu dữ liệu**: `role` trong DB là `text` (default `'STAFF'`), Prisma dùng enum `UserRole`. |
| **Location** | `locations` | **CONFLICTED** | 1. **Tên cột**: DB dùng hậu tố `_code` (`zone_code`, `aisle_code`, `rack_code`, `bin_code`), `location_barcode`, và `max_capacity_kg`. Prisma đang đặt tên thô (`zone`, `aisle`, `rack`, `bin`, `barcode`, `capacity`) mà chưa map.<br>2. **Kiểu dữ liệu**: `max_capacity_kg` trong DB là `numeric`, Prisma là `Int?`.<br>3. **Thiếu cột**: Trong DB không có `updated_at`.<br>4. **Constraint**: Trong DB chỉ có UNIQUE trên `location_barcode`; chưa có UNIQUE composite `(zone, aisle, rack, bin)`. |
| **InventoryItem** | `inventory_items` | **CONFLICTED** | 1. **Unique Key**: Trong DB có chỉ mục `UNIQUE (product_id, location_id, lot_number)` (rất chuẩn cho quản lý đa lot). Prisma lại chỉ khai báo `@@unique([productId, locationId])` (chặn nhiều lot tại 1 vị trí).<br>2. **Kiểu dữ liệu**: `expiry_date` trong DB là kiểu `date`, Prisma khai báo `String?`.<br>3. **Thiếu cột**: DB không có cột `created_at` (chỉ có `updated_at`). |
| **WarehouseOrder** | `warehouse_orders` | **CONFLICTED** | 1. **Thiếu cột**: Trong DB chưa có cột `reviewed_by` / `approved_by`.<br>2. **Kiểu dữ liệu**: `type` và `status` trong DB là `text`, Prisma dùng enums (`OrderType`, `OrderStatus`). |
| **StockLedger** | `stock_ledger` | **MISSING** | Bảng lịch sử thẻ kho append-only chưa được tạo trên cơ sở dữ liệu PostgreSQL. |
| **IdempotencyKey** | `idempotency_keys` | **MISSING** | Bảng quản lý khóa chống trùng lặp request chưa được tạo trên cơ sở dữ liệu PostgreSQL. |
| *(N/A)* | `your_table` | **ORPHAN** | Bảng rác ban đầu của Supabase Starter, cần dọn dẹp sau khi hệ sinh thái ổn định. |

---

## 5. PHÂN TÍCH RỦI RO NGHIỆP VỤ & TƯƠNG THÍCH FRONTEND FLUTTER

Đã thực hiện kiểm toán chéo mã nguồn Flutter (`lib/features/*/data/models/`):
- `LocationModel.fromJson`: đọc chính xác `zone_code`, `aisle_code`, `rack_code`, `bin_code`, `location_barcode`, `max_capacity_kg`.
- `ProfileModel.fromJson`: đọc `id`, `full_name`, `role`, `phone_number`, `created_at` (không đọc `email`).
- `InventoryItemModel.fromJson`: đọc `lot_number`, `expiry_date`, `updated_at` (không có `created_at`).

> [!CAUTION]
> **CẢNH BÁO NGUY CƠ PHÁ VỠ HỆ THỐNG**:
> Nếu chạy `prisma db push` hoặc tự ý chạy DDL sửa PostgreSQL để ép cơ sở dữ liệu theo `schema.prisma` hiện tại, các cột `zone_code`, `location_barcode`, `phone_number` sẽ bị xóa hoặc đổi tên, gây **CRASH TOÀN BỘ ỨNG DỤNG FLUTTER**.

---

## 6. ĐỀ XUẤT KẾ HOẠCH MIGRATION (TASK-DB-04 PLAN)

Chiến lược khuyến nghị: **Cập nhật `schema.prisma` để khớp với PostgreSQL & Flutter DTOs, sau đó tạo migration bổ sung các bảng còn thiếu an toàn**.

### Giai đoạn 1: Chuẩn hóa `schema.prisma` (Zero-Risk Refactoring)
1. Cập nhật model `Location`:
   - `@map("zone_code")`, `@map("aisle_code")`, `@map("rack_code")`, `@map("bin_code")`.
   - `@map("location_barcode")`, `@map("max_capacity_kg") Decimal?`.
   - Bỏ trường `updatedAt` hoặc để nullable.
2. Cập nhật model `Profile`:
   - Bỏ trường `email` khỏi model `Profile` (hoặc đánh dấu relation với auth schema).
   - Thêm `phoneNumber String? @map("phone_number")`.
   - Đổi `role String @default("STAFF")` để đồng bộ kiểu `text`.
3. Cập nhật model `InventoryItem`:
   - Đổi kiểu `expiryDate DateTime? @map("expiry_date") @db.Date`.
   - Bỏ `createdAt` hoặc để optional.
   - Sửa unique key thành: `@@unique([productId, locationId, lotNumber])`.
4. Cập nhật model `WarehouseOrderItem`:
   - Đổi kiểu `expiryDate DateTime? @map("expiry_date") @db.Date`.

### Giai đoạn 2: Tạo Migration bổ sung (Non-Breaking Additions)
Tạo script migration SQL chỉ bổ sung các bảng và cột mới, không làm thay đổi các bảng hiện tại:
1. Tạo bảng `stock_ledger` (cho tính năng thẻ kho).
2. Tạo bảng `idempotency_keys` (cho tính năng chống trùng lặp tạo đơn).
3. Bổ sung cột `reviewed_by uuid REFERENCES profiles(id)` (hoặc `approved_by`) vào `warehouse_orders` (nếu nghiệp vụ yêu cầu phê duyệt).
4. Drop bảng rác `your_table`.

---

## 7. KẾT QUẢ KIỂM THỬ TỔNG THỂ & BẢO TOÀN MÃ NGUỒN

- **Cấu hình `backend/.env`**: Đã sửa dấu `?` và bổ sung `sslmode=require&connection_limit=5&connect_timeout=15` an toàn, không để lộ secrets.
- **Offline Prisma Validation**: `npm run prisma:validate` -> **PASS**.
- **Unit Tests**: `npm run test` -> **33/33 tests PASS**.
- **E2E Tests**: `npm run test:e2e` -> **4/4 tests PASS**.
- **ESLint & TypeScript Build**: **PASS 100%**.

---

## 8. KẾT LUẬN & TRẠNG THÁI TIẾP THEO

- [x] Đã hoàn thành 100% mục tiêu của TASK-DB-03 Phase 2 trong phạm vi READ-ONLY nghiêm ngặt.
- [x] Không có bất kỳ bản ghi nghiệp vụ nào bị đọc hoặc rò rỉ.
- [x] Không có lệnh DDL (CREATE, ALTER, DROP) hay DML (INSERT, UPDATE, DELETE) nào được thực thi.
- [x] Nhánh `feature/backend-nestjs-init` an toàn, working tree sạch.

**DỪNG LẠI CHỜ PHÊ DUYỆT CỦA PROJECT OWNER CHO TASK-DB-04 (SCHEMA ALIGNMENT & MIGRATION).**
