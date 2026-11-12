# BÁO CÁO KỸ THUẬT: TASK-DB-04A — PRISMA SCHEMA ALIGNMENT (NO DATABASE WRITES)

- **Dự án**: InventoryAssistant — Smart Warehouse Management System
- **Hệ thống**: Backend (NestJS 12, TypeScript, Prisma 6.19.3) & Database (Supabase PostgreSQL 17.6)
- **Nhánh Git**: `feature/backend-nestjs-init`
- **Ngày thực hiện**: 12/11/2026
- **Kỹ sư phụ trách**: Senior NestJS Engineer / Prisma ORM Architect & QA Lead

---

## 1. TỔNG QUAN & BASELINE GIT (EXECUTIVE SUMMARY & GIT BASELINE)

- **Mục tiêu**: Điều chỉnh tệp định nghĩa schema `backend/prisma/schema.prisma` để khớp hoàn toàn với cấu trúc cơ sở dữ liệu PostgreSQL 17.6 thực tế đã kiểm chứng qua TASK-DB-03, đồng thời bảo vệ 100% tính tương thích với các Data Transfer Objects (DTOs) của ứng dụng di động Flutter.
- **Nguyên tắc an toàn (Safety Gate)**:
  - **KHÔNG kết nối cơ sở dữ liệu** trong toàn bộ quá trình thực hiện task.
  - **KHÔNG chạy** bất kỳ lệnh `prisma db push`, `prisma db pull`, hoặc `prisma migrate`.
  - **KHÔNG sửa đổi** mã nguồn của ứng dụng Flutter.
  - Toàn bộ kiểm thử và sinh mã Prisma Client (`prisma generate`) đều diễn ra **hoàn toàn offline**.
- **Tình trạng Git trước khi thực hiện**:
  - Head commit: `d4abd89` (`docs(backend): add TASK-DB-03 Supabase connection and schema audit report`).
  - Working tree sạch; tệp `.env` được bảo mật ngoài Git.

---

## 2. DANH SÁCH CÁC MODELS ĐÃ ĐIỀU CHỈNH

Toàn bộ 8 models trong `backend/prisma/schema.prisma` đã được rà soát và căn chỉnh:

1. **`Profile`** (`profiles`): Căn chỉnh theo cơ chế Supabase Auth, loại bỏ trường `email` không tồn tại trong bảng, bổ sung `phoneNumber`, chuẩn hóa `role` kiểu `text`.
2. **`Location`** (`locations`): Ánh xạ camelCase sang snake_case (`zone_code`, `aisle_code`, `rack_code`, `bin_code`, `location_barcode`, `max_capacity_kg Decimal?`), loại bỏ `updatedAt` và composite unique chưa có trong DB.
3. **`InventoryItem`** (`inventory_items`): Đổi `expiryDate` sang `@db.Date`, loại bỏ `createdAt`, cập nhật chỉ mục UNIQUE thành 3 cột `(productId, locationId, lotNumber)`.
4. **`WarehouseOrder`** (`warehouse_orders`): Chuẩn hóa `type` và `status` thành `String`, loại bỏ quan hệ `reviewedBy` chưa có trong DB.
5. **`WarehouseOrderItem`** (`warehouse_order_items`): Đổi `expiryDate` sang `@db.Date`.
6. **`Product`** (`products`): Cập nhật giá trị mặc định của `unit` thành `"Pcs"`.
7. **`StockLedger`** (`stock_ledger`): Đánh dấu model chờ tạo bảng trong migration tương lai (TASK-DB-04B).
8. **`IdempotencyKey`** (`idempotency_keys`): Đánh dấu model chờ tạo bảng trong migration tương lai (TASK-DB-04B).

---

## 3. BẢNG ĐỐI CHIẾU FIELD MAPPING CHI TIẾT (BEFORE VS AFTER)

### 3.1. Model `Profile` (bảng `profiles`)

| Tên trường (Prisma) | Trước căn chỉnh (Before) | Sau căn chỉnh (After) | Cột PostgreSQL thực tế | Ghi chú tương thích Flutter & Supabase Auth |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `String @id @default(uuid()) @db.Uuid` | `String @id @default(uuid()) @db.Uuid` | `id uuid PRIMARY KEY` | Khóa chính liên kết `auth.users(id)`. |
| `email` | `String @unique` | *(Đã loại bỏ)* | *(Không tồn tại)* | Email do Supabase Auth quản trị tại `auth.users`, không lưu trực tiếp tại bảng `profiles`. Flutter `ProfileModel` không đọc trường này. |
| `fullName` | `String? @map("full_name")` | `String @map("full_name")` | `full_name text NOT NULL` | Chuyển thành non-nullable để khớp ràng buộc `NOT NULL` của DB. |
| `role` | `UserRole @default(STAFF)` | `String @default("STAFF")` | `role text DEFAULT 'STAFF'` | Trong DB là kiểu `text`, không phải PostgreSQL enum. |
| `phoneNumber` | *(Chưa có)* | `String? @map("phone_number")` | `phone_number text NULL` | Bổ sung để khớp với trường `phone_number` mà Flutter `ProfileModel` đang sử dụng. |
| `createdAt` | `DateTime @default(now()) @db.Timestamptz(6)` | `DateTime @default(now()) @db.Timestamptz(6)` | `created_at timestamptz` | Khớp 100%. |
| `updatedAt` | `DateTime @updatedAt @db.Timestamptz(6)` | `DateTime @default(now()) @updatedAt @db.Timestamptz(6)` | `updated_at timestamptz` | Khớp 100%. |

---

### 3.2. Model `Location` (bảng `locations`)

| Tên trường (Prisma) | Trước căn chỉnh (Before) | Sau căn chỉnh (After) | Cột PostgreSQL thực tế | Ghi chú tương thích Flutter |
| :--- | :--- | :--- | :--- | :--- |
| `zoneCode` | `zone String` | `zoneCode String @map("zone_code")` | `zone_code text NOT NULL` | Khớp với Flutter `zoneCode` (`json['zone_code']`). |
| `aisleCode` | `aisle String` | `aisleCode String @map("aisle_code")` | `aisle_code text NOT NULL` | Khớp với Flutter `aisleCode` (`json['aisle_code']`). |
| `rackCode` | `rack String` | `rackCode String @map("rack_code")` | `rack_code text NOT NULL` | Khớp với Flutter `rackCode` (`json['rack_code']`). |
| `binCode` | `bin String` | `binCode String @map("bin_code")` | `bin_code text NOT NULL` | Khớp với Flutter `binCode` (`json['bin_code']`). |
| `locationBarcode`| `barcode String @unique` | `locationBarcode String @unique @map("location_barcode")` | `location_barcode text UNIQUE` | Khớp với Flutter `locationBarcode` (`json['location_barcode']`). |
| `maxCapacityKg` | `capacity Int?` | `maxCapacityKg Decimal? @map("max_capacity_kg") @db.Decimal` | `max_capacity_kg numeric NULL` | Sử dụng kiểu `Decimal` để tương thích chính xác với PostgreSQL `numeric` và Flutter `double?`. |
| `createdAt` | `DateTime @default(now())` | `DateTime @default(now())` | `created_at timestamptz` | Khớp 100%. |
| `updatedAt` | `DateTime @updatedAt` | *(Đã loại bỏ)* | *(Không tồn tại)* | Trong PostgreSQL và Flutter `LocationModel` không có cột `updated_at`. |
| Constraints | `@@unique([zone, aisle, rack, bin])` | *(Đã loại bỏ)* | *(Không tồn tại)* | DB thực tế chỉ có UNIQUE trên `location_barcode`. |

---

### 3.3. Model `InventoryItem` (bảng `inventory_items`)

| Tên trường (Prisma) | Trước căn chỉnh (Before) | Sau căn chỉnh (After) | Cột PostgreSQL thực tế | Ghi chú tương thích Flutter |
| :--- | :--- | :--- | :--- | :--- |
| `productId` | `String @map("product_id")` | `String @map("product_id")` | `product_id uuid NOT NULL` | Foreign key tới `products(id)`. |
| `locationId` | `String @map("location_id")` | `String @map("location_id")` | `location_id uuid NOT NULL` | Foreign key tới `locations(id)`. |
| `quantityOnHand`| `Int @default(0)` | `Int @default(0)` | `quantity_on_hand int4 NOT NULL` | Khớp 100%. |
| `quantityReserved`| `Int @default(0)` | `Int @default(0)` | `quantity_reserved int4 NOT NULL`| Khớp 100%. |
| `lotNumber` | `String? @map("lot_number")` | `String? @map("lot_number")` | `lot_number text NULL` | Khớp 100%. |
| `expiryDate` | `String? @map("expiry_date")` | `DateTime? @map("expiry_date") @db.Date` | `expiry_date date NULL` | Chuẩn hóa kiểu Date của PostgreSQL. Flutter parse bằng `DateTime.tryParse()`. |
| `createdAt` | `DateTime @default(now())` | *(Đã loại bỏ)* | *(Không tồn tại)* | DB thực tế và Flutter `InventoryItemModel` không có cột `created_at`. |
| `updatedAt` | `DateTime @updatedAt` | `DateTime @default(now()) @updatedAt @db.Timestamptz(6)` | `updated_at timestamptz` | Khớp 100%. |
| Constraints | `@@unique([productId, locationId])` | `@@unique([productId, locationId, lotNumber])` | `inventory_items_product_id_location_id_lot_number_key` | Khớp chỉ mục UNIQUE 3 cột trong PostgreSQL, hỗ trợ đa lot tại cùng vị trí. |

---

### 3.4. Model `WarehouseOrder` (bảng `warehouse_orders`)

| Tên trường (Prisma) | Trước căn chỉnh (Before) | Sau căn chỉnh (After) | Cột PostgreSQL thực tế | Ghi chú tương thích Flutter |
| :--- | :--- | :--- | :--- | :--- |
| `orderCode` | `String @unique @map("order_code")` | `String @unique @map("order_code")` | `order_code text UNIQUE` | Khớp 100%. |
| `type` | `OrderType` (Enum) | `String` | `type text NOT NULL` | PostgreSQL lưu giá trị text (`INBOUND` / `OUTBOUND`). |
| `status` | `OrderStatus @default(DRAFT)`| `String @default("DRAFT")` | `status text DEFAULT 'DRAFT'` | PostgreSQL lưu giá trị text. |
| `createdBy` | `String? @map("created_by")` | `String? @map("created_by")` | `created_by uuid NULL` | Foreign key tới `profiles(id)`. |
| `reviewedBy` | `String? @map("reviewed_by")` | *(Tạm loại bỏ)* | *(Không tồn tại)* | Cột này chưa tồn tại trong PostgreSQL, sẽ bổ sung trong TASK-DB-04B. |
| `note` | `String?` | `String?` | `note text NULL` | Khớp 100%. |
| `createdAt` | `DateTime @default(now())` | `DateTime @default(now())` | `created_at timestamptz` | Khớp 100%. |
| `updatedAt` | `DateTime @updatedAt` | `DateTime @default(now()) @updatedAt` | `updated_at timestamptz` | Khớp 100%. |

---

### 3.5. Model `WarehouseOrderItem` (bảng `warehouse_order_items`)

| Tên trường (Prisma) | Trước căn chỉnh (Before) | Sau căn chỉnh (After) | Cột PostgreSQL thực tế | Ghi chú tương thích |
| :--- | :--- | :--- | :--- | :--- |
| `expiryDate` | `String? @map("expiry_date")` | `DateTime? @map("expiry_date") @db.Date` | `expiry_date date NULL` | Chuẩn hóa kiểu Date của PostgreSQL. |
| Các trường khác | Giữ nguyên | Giữ nguyên | Khớp 100% | `order_id`, `product_id`, `location_id`, `expected_quantity`, `actual_quantity`, `lot_number`, `created_at`. |

---

### 3.6. Model `Product` (bảng `products`)

- Đã điều chỉnh giá trị mặc định của trường `unit`: từ `@default("Cái")` thành `@default("Pcs")` để đồng bộ với `unit text DEFAULT 'Pcs'::text` trong cơ sở dữ liệu PostgreSQL.

---

## 4. NHỮNG KHÁC BIỆT CHƯA XỬ LÝ (DEFERRED TO TASK-DB-04B)

1. **Hai bảng chưa tồn tại trên PostgreSQL**:
   - `StockLedger` (`stock_ledger`): Bảng thẻ kho phục vụ truy vết biến động tồn kho.
   - `IdempotencyKey` (`idempotency_keys`): Bảng lưu trữ token chống trùng lặp request giao dịch.
   - *Biện pháp hiện tại*: Giữ nguyên định nghĩa model trong `schema.prisma` và đánh dấu ghi chú rõ ràng. Prisma Client đã sinh mã types hoàn tất mà không yêu cầu database phải có bảng ngay lập tức.
2. **Cột phê duyệt phiếu kho (`approved_by` / `reviewed_by`)**:
   - Flutter `WarehouseOrderModel` có trường `approved_by`, nhưng bảng `warehouse_orders` trên PostgreSQL hiện tại chưa có cột này.
   - Sẽ được bổ sung an toàn qua lệnh `ALTER TABLE` trong kịch bản migration của TASK-DB-04B.
3. **Bảng rác `your_table`**:
   - Bảng placeholder ban đầu của Supabase Starter không nằm trong Prisma schema. Sẽ được DROP dọn dẹp trong TASK-DB-04B.

---

## 5. KẾT QUẢ KIỂM THỬ TỔNG THỂ (TEST RESULTS)

Tất cả các kiểm thử đều thực hiện ở chế độ **OFFLINE** không kết nối database:

| Kiểm thử | Lệnh thực thi | Kết quả | Chi tiết |
| :--- | :--- | :---: | :--- |
| **Prisma Schema Validation** | `npm run prisma:validate` | **PASS** | `The schema at prisma\schema.prisma is valid 🚀` |
| **Prisma Client Generation** | `npm run prisma:generate` | **PASS** | `Generated Prisma Client (v6.19.3) in 73ms` |
| **ESLint** | `npm run lint` | **PASS** | 0 errors, 0 warnings. |
| **TypeScript Build** | `npm run build` | **PASS** | `nest build` biên dịch thành công 100%. |
| **Unit Tests** | `npm run test` | **PASS** | **8/8 test suites, 39/39 tests passed** (Bổ sung 6 tests mới trong `prisma.schema.spec.ts`). |
| **E2E Tests** | `npm run test:e2e` | **PASS** | **1/1 test suite, 5/5 tests passed** (Chạy hoàn toàn trên mock `PrismaService`, cách ly 100% với database). |

**TỔNG CỘNG: 44/44 TESTS PASSED (100%)**

---

## 6. DANH SÁCH TỆP THAY ĐỔI & COMMITS

- `backend/prisma/schema.prisma`: Căn chỉnh toàn bộ 8 models theo PostgreSQL thực tế.
- `backend/src/prisma/prisma.schema.spec.ts`: Bộ kiểm thử types và compatibility cho schema mới.
- `backend/test/app.e2e-spec.ts`: Tách biệt e2e test khỏi database thật bằng mock provider.
- `docs/audits/TASK-DB-04A_PRISMA_SCHEMA_ALIGNMENT_REPORT.md`: Báo cáo kỹ thuật chi tiết.

### Commit Hash:
- [`d91f651`](https://github.com/nhon2511/InventoryAssistant/commit/d91f651) — `refactor(prisma): align schema with Supabase PostgreSQL and Flutter DTOs`

---

## 7. ĐỀ XUẤT KẾ HOẠCH CHO TASK-DB-04B (NON-BREAKING MIGRATION)

Sau khi hoàn thành căn chỉnh Prisma schema cục bộ ở TASK-DB-04A, đề xuất kế hoạch cho **TASK-DB-04B**:
1. **Tạo kịch bản Migration SQL không gây gián đoạn**:
   ```sql
   -- 1. Tạo bảng stock_ledger
   CREATE TABLE IF NOT EXISTS public.stock_ledger (
     id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
     transaction_type text NOT NULL,
     product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
     location_id uuid NOT NULL REFERENCES public.locations(id) ON DELETE RESTRICT,
     delta integer NOT NULL,
     balance integer NOT NULL,
     order_id uuid NULL,
     created_by uuid NULL,
     note text NULL,
     created_at timestamptz NOT NULL DEFAULT now()
   );

   -- 2. Tạo bảng idempotency_keys
   CREATE TABLE IF NOT EXISTS public.idempotency_keys (
     key text PRIMARY KEY,
     path text NOT NULL,
     status_code integer NOT NULL,
     response jsonb NOT NULL,
     created_at timestamptz NOT NULL DEFAULT now()
   );

   -- 3. Bổ sung approved_by vào warehouse_orders (tương thích Flutter & Backend)
   ALTER TABLE public.warehouse_orders 
   ADD COLUMN IF NOT EXISTS approved_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL;

   -- 4. Dọn dẹp bảng starter
   DROP TABLE IF EXISTS public.your_table;
   ```
2. **Kiểm thử áp dụng Migration trên môi trường Development** sau khi được Project Owner phê duyệt.
