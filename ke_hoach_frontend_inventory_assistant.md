# KẾ HOẠCH & PHÂN CÔNG CÔNG VIỆC FRONTEND - INVENTORY ASSISTANT

> **Mục đích:** Tài liệu dùng để phân công và theo dõi các task Frontend trên GitHub.
>
> **Phạm vi hiện tại:** Tập trung hoàn thiện giao diện và luồng xử lý phía Frontend bằng Flutter. Trong giai đoạn này ưu tiên hoàn thiện UI, navigation, form, component dùng chung, trạng thái giao diện và các luồng tương tác bằng dữ liệu mock. Chưa cần triển khai Backend/API thật.

---

# PHÂN CÔNG FRONTEND

| Thành viên | Nhiệm vụ chính |
|---|---|
| **Thuận** | Layout, Navigation, Dashboard, UI Components |
| **Vũ** | Inventory, Product, Batch/LOT |
| **Khánh Hòa** | Inbound, Outbound, Form nghiệp vụ |
| **Cả nhóm** | Barcode/QR, OCR, AI Assistant UI, Integration |

> Các thành viên có thể hỗ trợ nhau khi hoàn thành task chính. Mỗi task sau khi hoàn thành cần được commit và tạo Pull Request để review.

---

# TUẦN 1: DỰNG KHUNG FRONTEND & UI COMPONENTS

### Mục tiêu

Hoàn thiện cấu trúc giao diện chính của ứng dụng Flutter, các component dùng chung và navigation. Toàn bộ dữ liệu trong tuần này có thể sử dụng mock data.

## 1. Layout & Navigation - Thuận

- Hoàn thiện App Layout.
- Hoàn thiện AppBar/Header.
- Hoàn thiện Sidebar/Navigation.
- Hoàn thiện Bottom Navigation nếu cần trên mobile.
- Tạo menu:
  - Dashboard.
  - Inventory.
  - Inbound.
  - Outbound.
  - AI Assistant.
  - Profile/Settings nếu có trong repo.
- Hoàn thiện routing giữa các màn hình.
- Xử lý trạng thái màn hình hiện tại trên Navigation.

## 2. UI Components - Thuận

Tạo các component dùng chung:

- Custom Button.
- Custom TextField.
- Dropdown/Select.
- Search Bar.
- Card.
- Data Table/List.
- Dialog.
- Bottom Sheet.
- Snackbar/Toast.
- Loading.
- Empty State.
- Error State.
- Confirmation Dialog.

Mục tiêu là các màn hình khác tái sử dụng component, hạn chế viết UI trùng lặp.

## 3. Dashboard - Thuận

Dựng giao diện Dashboard:

- Tổng số sản phẩm.
- Tổng số lượng tồn.
- Sản phẩm sắp hết.
- Sản phẩm hết hàng.
- Thống kê nhập kho.
- Thống kê xuất kho.
- Biểu đồ.
- Recent Activities/Transactions nếu có trong thiết kế.

Dùng mock data để hoàn thiện UI trước.

## 4. Inventory - Vũ

Dựng màn hình Inventory:

- Danh sách sản phẩm.
- Search sản phẩm.
- Filter.
- Sort.
- Hiển thị số lượng tồn.
- Hiển thị Batch/LOT.
- Hiển thị Location.
- Hiển thị trạng thái:
  - Còn hàng.
  - Sắp hết.
  - Hết hàng.
- Trang/Popup xem chi tiết sản phẩm.

### Chi tiết sản phẩm

Khi chọn một sản phẩm:

- Tên sản phẩm.
- Hình ảnh.
- SKU/Barcode.
- Số lượng tồn.
- Batch/LOT.
- EXP/HSD.
- Vị trí trong kho.
- Thông tin liên quan.

## 5. Inbound - Khánh Hòa

Dựng giao diện Nhập kho:

- Danh sách phiếu nhập.
- Nút tạo phiếu nhập.
- Form nhập hàng.
- Chọn sản phẩm.
- Nhập số lượng.
- Nhập Batch/LOT.
- Nhập EXP/HSD.
- Chọn Location.
- Danh sách sản phẩm trong phiếu.
- Tổng số lượng.
- Nút Save/Draft.
- Nút Confirm.

### Trạng thái phiếu

Thiết kế UI cho các trạng thái:

- Draft.
- Pending.
- Confirmed.
- Completed.

## 6. Outbound - Khánh Hòa

Dựng giao diện Xuất kho:

- Danh sách phiếu xuất.
- Tạo phiếu xuất.
- Chọn sản phẩm.
- Nhập số lượng.
- Chọn Batch/LOT.
- Chọn Location.
- Hiển thị tồn kho hiện tại.
- Cảnh báo khi số lượng xuất lớn hơn số lượng tồn.
- Danh sách sản phẩm trong phiếu.
- Nút Save/Draft.
- Nút Confirm.

---

# TUẦN 2: HOÀN THIỆN CÁC LUỒNG NGHIỆP VỤ FRONTEND

### Mục tiêu

Các màn hình chính phải có thể thao tác hoàn chỉnh bằng mock data, không chỉ là giao diện tĩnh.

## 1. Inventory - Vũ

- Hoàn thiện Search.
- Hoàn thiện Filter.
- Hoàn thiện Sort.
- Hoàn thiện Product Detail.
- Hoàn thiện Batch/LOT Detail.
- Hoàn thiện trạng thái tồn kho.
- Thêm Empty State.
- Thêm Loading State.
- Thêm Error State.
- Hoàn thiện responsive UI.

## 2. Inbound - Khánh Hòa

Hoàn thiện flow:

**Danh sách → Tạo phiếu → Thêm sản phẩm → Kiểm tra → Lưu Draft → Confirm**

Các validation:

- Không được bỏ trống sản phẩm.
- Số lượng phải > 0.
- Batch/LOT hợp lệ.
- EXP/HSD hợp lệ.
- Không cho submit khi dữ liệu chưa đầy đủ.

## 3. Outbound - Khánh Hòa

Hoàn thiện flow:

**Danh sách → Tạo phiếu → Chọn sản phẩm → Nhập số lượng → Kiểm tra tồn → Lưu Draft → Confirm**

UI cảnh báo:

- Không đủ tồn kho.
- Số lượng không hợp lệ.
- Chưa chọn sản phẩm.
- Chưa chọn Batch/LOT.
- Chưa chọn Location.

## 4. Dashboard - Thuận

- Hoàn thiện các Card thống kê.
- Hoàn thiện biểu đồ.
- Hoàn thiện bảng Recent Activities.
- Hoàn thiện responsive.
- Thống nhất UI với Inventory/Inbound/Outbound.

## 5. UI/UX Review - Cả nhóm

Kiểm tra:

- Khoảng cách.
- Font.
- Kích thước Button.
- Icon.
- Alignment.
- Màu trạng thái.
- Loading.
- Empty State.
- Error State.
- Dialog.
- Responsive.

---

# TUẦN 3: BARCODE / QR, OCR & CÁC TÍNH NĂNG TƯƠNG TÁC

### Mục tiêu

Tích hợp các tính năng camera vào Frontend và hoàn thiện trải nghiệm nhập/xuất kho.

## 1. Barcode / QR - Cả nhóm

- Tạo màn hình/Popup Scanner.
- Mở camera.
- Quét Barcode/QR.
- Hiển thị kết quả sau khi quét.
- Tìm sản phẩm tương ứng từ mock data.
- Tự động điền sản phẩm vào form.
- Xử lý:
  - Mã hợp lệ.
  - Mã không tồn tại.
  - Mã bị trùng.
  - Scan thất bại.
- Cho phép scan lại.

### Gắn vào Inbound

**Scan → Tìm sản phẩm → Thêm vào phiếu nhập**

### Gắn vào Outbound

**Scan → Tìm sản phẩm → Kiểm tra tồn → Thêm vào phiếu xuất**

## 2. OCR - Cả nhóm

Dựng UI OCR để nhận diện thông tin trên sản phẩm.

Thông tin cần hỗ trợ:

- LOT/Batch.
- EXP/HSD.

Flow:

**Camera/Image → OCR → Hiển thị kết quả → Người dùng kiểm tra → Điền vào Form**

Yêu cầu:

- Không tự động lưu ngay kết quả OCR.
- Cho phép người dùng sửa kết quả OCR.
- Hiển thị trạng thái đang nhận diện.
- Xử lý trường hợp OCR không nhận diện được.

## 3. Inventory UI - Vũ

Bổ sung:

- Filter theo Batch.
- Filter theo EXP/HSD.
- Filter theo Location.
- Hiển thị cảnh báo hàng sắp hết hạn.
- Hiển thị sản phẩm theo trạng thái tồn kho.

## 4. Inbound / Outbound - Khánh Hòa

Tích hợp UI Barcode/QR và OCR vào:

- Form Inbound.
- Form Outbound.

Đảm bảo các component mới không phá vỡ layout hiện tại.

---

# TUẦN 4: AI ASSISTANT UI & HOÀN THIỆN FRONTEND

### Mục tiêu

Hoàn thiện giao diện AI Assistant, kết nối toàn bộ các màn hình và kiểm tra Frontend trước khi bàn giao cho giai đoạn tích hợp Backend.

## 1. AI Assistant UI - Cả nhóm

Dựng giao diện Chat Assistant:

- Chat List.
- Message Bubble.
- User Message.
- AI Message.
- Loading/Typing Indicator.
- Input Box.
- Send Button.
- Clear Chat nếu cần.

### Hiển thị kết quả AI

AI có thể trả về:

- Câu trả lời dạng text.
- Thông tin tồn kho.
- Thông tin sản phẩm.
- Draft Inbound.
- Draft Outbound.

## 2. AI tạo Draft - Cả nhóm

Thiết kế UI cho trường hợp:

> “Lấy 5 thùng mì Hảo Hảo.”

AI trả về thông tin:

```json
{
  "action": "EXPORT",
  "product": "Mì Hảo Hảo",
  "quantity": 5
}
```

Frontend hiển thị Draft Outbound:

- Sản phẩm.
- Số lượng.
- Batch/LOT nếu có.
- Location nếu có.
- Nút Xác nhận.
- Nút Hủy.
- Nút Chỉnh sửa.

Sau này khi Backend được tích hợp, Draft này sẽ được gửi sang nghiệp vụ Outbound.

## 3. Frontend Integration - Cả nhóm

Kiểm tra các luồng chính:

- Login → Dashboard.
- Dashboard → Inventory.
- Dashboard → Inbound.
- Dashboard → Outbound.
- Dashboard → AI Assistant.
- Inventory → Product Detail.
- Inbound → Scanner/OCR.
- Outbound → Scanner/OCR.
- AI → Draft Inbound/Outbound.

## 4. UI State - Cả nhóm

Mỗi màn hình cần có các trạng thái phù hợp:

- Loading.
- Success.
- Empty.
- Error.
- Confirmation.
- Validation.

## 5. Final Review - Cả nhóm

- Kiểm tra UI toàn bộ ứng dụng.
- Kiểm tra responsive.
- Kiểm tra các form.
- Kiểm tra navigation.
- Kiểm tra Barcode/QR.
- Kiểm tra OCR.
- Kiểm tra AI Assistant UI.
- Chạy `flutter analyze`.
- Sửa lỗi compile và warning quan trọng.
- Review code.
- Chuẩn bị Frontend để bắt đầu tích hợp Backend/Supabase.
