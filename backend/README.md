# 📦 Smart WMS — Backend Service (NestJS + Prisma + Supabase)

Dịch vụ backend xử lý nghiệp vụ trung tâm cho hệ sinh thái quản lý kho hàng **Smart WMS**, được xây dựng trên nền tảng **NestJS (TypeScript)**, **Prisma ORM** và **Supabase PostgreSQL**.

---

## 🏛️ Kiến Trúc Hệ Thống

```text
Flutter Mobile / Web  ──(Bearer JWT)──►  NestJS API Gateway (/api/v1)
                                              │
                      ┌───────────────────────┴───────────────────────┐
                      ▼                                               ▼
             Supabase Auth (GoTrue)                        PostgreSQL Database
             - JWT Signature Verify                        - Prisma Client (ACID Transactions)
             - User Profiles & Roles                       - Supavisor Connection Pool (6543)
```

- **REST API Prefix**: `/api/v1`
- **Swagger Documentation**: `/docs`
- **Health Check Endpoint**: `/api/v1/health`

---

## 🚫 Chính Sách Không Dùng Docker (NO DOCKER POLICY)

Dự án tuân thủ nghiêm ngặt nguyên tắc phát triển trực tiếp trên môi trường máy chủ cục bộ (Node.js runtime):
- Không yêu cầu hay sử dụng Docker / Docker Compose.
- Kết nối trực tiếp tới cơ sở dữ liệu Supabase Cloud (development/staging project).
- Khởi chạy nhanh chóng bằng lệnh tiêu chuẩn `npm run start:dev`.

---

## ⚙️ Yêu Cầu Môi Trường & Cài Đặt

### 1. Yêu cầu tiên quyết
- **Node.js**: `>= 20.x` (khuyến nghị `22.x` hoặc `24.x`)
- **npm**: `>= 10.x`

### 2. Cài đặt Dependencies
```bash
cd backend
npm install
npm run prisma:generate
```

### 3. Cấu hình biến môi trường
Tạo file `.env` tại thư mục `backend/` dựa trên mẫu `.env.example`:
```bash
cp .env.example .env
```

Cấu hình các tham số chính:
```env
PORT=3000
API_PREFIX=/api/v1
NODE_ENV=development

# Chuỗi kết nối Supabase Cloud:
# Direct connection (Session mode):
DIRECT_URL="postgresql://postgres.[REF]:[PASS]@aws-0-[REGION].pooler.supabase.com:5432/postgres?sslmode=require"
# Transaction Pooler (Supavisor port 6543):
DATABASE_URL="postgresql://postgres.[REF]:[PASS]@aws-0-[REGION].pooler.supabase.com:6543/postgres?pgbouncer=true&sslmode=require"

# Supabase Auth
SUPABASE_URL="https://your-project.supabase.co"
SUPABASE_ANON_KEY="your-anon-key"
SUPABASE_JWT_SECRET="your-jwt-secret"
```

---

## 🚀 Khởi Chạy Ứng Dụng

Tại thư mục `backend/`:
```bash
# Development mode (Hot-reload)
npm run start:dev

# Production build
npm run build
npm run start:prod
```

Hoặc chạy từ thư mục gốc của repository:
```bash
npm run backend:dev
```

Truy cập:
- **API Base**: `http://localhost:3000/api/v1`
- **Health Check**: `http://localhost:3000/api/v1/health`
- **Swagger Docs**: `http://localhost:3000/docs`

---

## 🧪 Kiểm Thử & Kiểm Soát Chất Lượng (Quality Gates)

```bash
# Kiểm tra linter
npm run lint

# Chạy Unit Tests
npm test

# Chạy E2E Tests
npm run test:e2e

# Biên dịch mã nguồn
npm run build
```

---

## 🛡️ Nguyên Tắc An Toàn Dữ Liệu (Database Safety)

1. **Không chạy `prisma db push` hay `prisma migrate deploy` trên Production Database** mà chưa có kế hoạch review được phê duyệt.
2. Không commit file `.env` chứa mật khẩu thực vào Git repository.
3. Khi phát triển cục bộ, sử dụng project Supabase Development riêng biệt.
