# Hướng Dẫn Kết Nối Và Cài Đặt Dependencies Supabase

## 1. Cài đặt Thư viện Supabase
Cài đặt thư viện thông qua npm:
```bash
npm install @supabase/supabase-js dotenv
```

## 2. Tạo File `.env`
Tạo file `.env` trong thư mục gốc của dự án và thêm nội dung:
```env
SUPABASE_URL=https://<your-supabase-url>.supabase.co
SUPABASE_KEY=<your-supabase-key>
```
- **SUPABASE_URL:** Có thể tìm thấy trong Supabase Console → **Settings** → **API**.
- **SUPABASE_KEY:** Sử dụng `anon-public` key từ Supabase Console.

## 3. Khởi tạo Supabase Client
Tạo file `supabaseClient.js` để cấu hình Supabase Client:
```javascript
import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';

dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_KEY;

export const supabase = createClient(supabaseUrl, supabaseKey);
```

## 4. Kiểm tra Kết nối
Tạo file `testSupabase.js`:
```javascript
import { supabase } from './supabaseClient';

async function fetchTestData() {
  const { data, error } = await supabase
    .from('test_table')
    .select('*');

  if (error) {
    console.error('Error fetching data:', error);
  } else {
    console.log('Fetched data:', data);
  }
}

fetchTestData();
```
Sau đó chạy lệnh kiểm tra:
```bash
node testSupabase.js
```
Nếu thành công, dữ liệu sẽ được hiển thị trên console.

## 5. Thêm `.gitignore`
Đảm bảo file `.gitignore` đã loại trừ các file nhạy cảm và không cần thiết:
```gitignore
# Environment variables
.env

# Node modules
node_modules/
```