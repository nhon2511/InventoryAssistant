# USER STORIES – INVENTORY ASSISTANT

## 1. Xác thực và phân quyền

### US-01 – Đăng nhập hệ thống

**User Story**

Là người dùng hệ thống, tôi muốn đăng nhập vào ứng dụng để truy cập các chức năng phù hợp với tài khoản của mình.

**Acceptance Criteria**
- Người dùng phải đăng nhập thành công mới được truy cập hệ thống.
- Hệ thống xác định vai trò của người dùng.
- Người dùng được cấp quyền phù hợp với vai trò.

**Priority:** High

---

### US-02 – Phân quyền người dùng

**User Story**

Là quản trị viên, tôi muốn phân quyền người dùng theo vai trò để kiểm soát quyền truy cập và thao tác dữ liệu kho.

**Acceptance Criteria**
- Hệ thống hỗ trợ các vai trò ADMIN, MANAGER và STAFF.
- ADMIN/MANAGER có quyền thực hiện các thao tác quản lý phù hợp.
- STAFF có quyền thực hiện các thao tác nghiệp vụ kho được cấp phép.
- Người dùng không thể truy cập chức năng ngoài quyền hạn.

**Priority:** High


## 2. Nhập kho

### US-03 – Quét Barcode/QR hàng loạt

**User Story**

Là thủ kho, tôi muốn quét liên tục nhiều mã Barcode/QR bằng camera điện thoại để nhập nhiều sản phẩm vào kho nhanh chóng mà không phải nhập mã thủ công.

**Acceptance Criteria**
- Có thể quét Barcode/QR bằng camera.
- Có thể quét nhiều sản phẩm liên tiếp.
- Quét trùng mã có thể cộng dồn số lượng.
- Hệ thống cảnh báo khi số lượng vượt dự kiến.

**Priority:** High


### US-04 – Nhận diện số lô và hạn sử dụng bằng OCR

**User Story**

Là thủ kho, tôi muốn sử dụng camera để nhận diện số lô và hạn sử dụng trên bao bì sản phẩm để giảm việc nhập dữ liệu thủ công.

**Acceptance Criteria**
- Người dùng có thể chụp/scan thông tin sản phẩm.
- Hệ thống nhận diện số lô.
- Hệ thống nhận diện hạn sử dụng.
- Kết quả nhận diện được đưa vào thông tin nhập kho.

**Priority:** High


### US-05 – Tạo phiếu nhập kho

**User Story**

Là thủ kho, tôi muốn tạo phiếu nhập kho từ các sản phẩm đã quét để ghi nhận hàng hóa được đưa vào kho.

**Acceptance Criteria**
- Có thể tạo phiếu nhập kho.
- Phiếu chứa danh sách sản phẩm và số lượng.
- Có thể lưu số lô, hạn sử dụng và vị trí.
- Có thể kiểm tra phiếu trước khi xác nhận.
- Khi xác nhận, tồn kho được cập nhật.

**Priority:** High


## 3. Quản lý tồn kho

### US-06 – Tra cứu tồn kho

**User Story**

Là nhân viên kho, tôi muốn tra cứu số lượng sản phẩm đang tồn tại trong kho để biết chính xác lượng hàng hiện có.

**Acceptance Criteria**
- Có thể tìm kiếm sản phẩm.
- Hiển thị số lượng tồn.
- Hiển thị vị trí lưu trữ.
- Hiển thị thông tin tồn kho liên quan.

**Priority:** High


### US-07 – Theo dõi vị trí sản phẩm

**User Story**

Là thủ kho, tôi muốn biết chính xác sản phẩm đang nằm ở vị trí nào để tìm hàng nhanh hơn.

**Acceptance Criteria**
- Sản phẩm được liên kết với vị trí.
- Hiển thị thông tin vị trí sản phẩm.
- Vị trí được tổ chức theo cấu trúc kho.

**Priority:** Medium


### US-08 – Cảnh báo tồn kho thấp

**User Story**

Là quản lý kho, tôi muốn nhận biết các sản phẩm có lượng tồn dưới mức an toàn để chủ động xử lý tình trạng thiếu hàng.

**Acceptance Criteria**
- Mỗi sản phẩm có mức tồn kho an toàn.
- Hệ thống so sánh tồn kho với mức an toàn.
- Sản phẩm dưới mức an toàn được cảnh báo.
- Cảnh báo được hiển thị trên Dashboard.

**Priority:** High


## 4. Xuất kho

### US-09 – Tạo Pick List

**User Story**

Là thủ kho, tôi muốn nhận danh sách sản phẩm cần lấy kèm vị trí kệ để chuẩn bị hàng xuất kho nhanh và chính xác.

**Acceptance Criteria**
- Hiển thị danh sách sản phẩm cần lấy.
- Hiển thị số lượng cần lấy.
- Hiển thị vị trí sản phẩm.
- Có thể sử dụng danh sách để thực hiện picking.

**Priority:** High


### US-10 – Quét đối soát khi xuất kho

**User Story**

Là thủ kho, tôi muốn quét mã sản phẩm trước khi đóng gói để đảm bảo đúng mã hàng và đúng số lượng cần xuất.

**Acceptance Criteria**
- Quét đúng sản phẩm thì được xác nhận.
- Quét sai sản phẩm thì hệ thống cảnh báo.
- Quét vượt số lượng yêu cầu thì hệ thống cảnh báo.
- Sản phẩm đã xác nhận được đánh dấu hoàn thành.

**Priority:** High


### US-11 – Cập nhật tồn kho khi xuất hàng

**User Story**

Là quản lý kho, tôi muốn hệ thống tự động trừ số lượng hàng đã xuất khỏi tồn kho để số liệu tồn kho luôn chính xác.

**Acceptance Criteria**
- Hệ thống kiểm tra phiếu trước khi hoàn tất.
- Không cho phép tồn kho âm.
- Số lượng hàng xuất được trừ khỏi tồn kho.
- Phiếu được cập nhật trạng thái hoàn tất.

**Priority:** High


## 5. AI Assistant

### US-12 – Tra cứu kho bằng ngôn ngữ tự nhiên

**User Story**

Là thủ kho hoặc quản lý kho, tôi muốn hỏi thông tin tồn kho bằng ngôn ngữ tự nhiên để nhanh chóng biết sản phẩm còn bao nhiêu và đang ở đâu.

**Ví dụ**

"Mì Hảo Hảo còn bao nhiêu ở kệ A1?"

**Acceptance Criteria**
- Người dùng có thể nhập câu hỏi tự nhiên.
- AI nhận diện được sản phẩm.
- AI nhận diện được vị trí nếu có.
- Hệ thống truy vấn dữ liệu tồn kho.
- Kết quả được trả về bằng ngôn ngữ tự nhiên.

**Priority:** High


### US-13 – Tạo phiếu bằng AI

**User Story**

Là thủ kho, tôi muốn nhập câu lệnh tự nhiên để AI tự động tạo bản nháp phiếu nhập/xuất nhằm giảm thao tác nhập biểu mẫu.

**Ví dụ**

"Nhập 50 thùng nước vào kệ A1."

**Acceptance Criteria**
- AI nhận diện được loại nghiệp vụ.
- AI nhận diện sản phẩm.
- AI nhận diện số lượng.
- AI nhận diện vị trí nếu có.
- Hệ thống tạo phiếu ở trạng thái Draft.
- Người dùng kiểm tra trước khi xác nhận.
- AI không tự ý ghi dữ liệu khi chưa có xác nhận.

**Priority:** High


### US-14 – Nhập lệnh bằng giọng nói

**User Story**

Là thủ kho, tôi muốn nhập yêu cầu bằng giọng nói để có thể thao tác với hệ thống trong khi đang xử lý hàng hóa.

**Acceptance Criteria**
- Hệ thống nhận giọng nói.
- Chuyển giọng nói thành văn bản.
- AI xử lý nội dung văn bản.
- Người dùng có thể kiểm tra trước khi xác nhận.

**Priority:** Medium


## 6. Dashboard

### US-15 – Theo dõi tồn kho Realtime

**User Story**

Là quản lý kho, tôi muốn Dashboard tự động cập nhật số liệu tồn kho khi nhân viên nhập hoặc xuất hàng để luôn nắm được tình trạng kho hiện tại.

**Acceptance Criteria**
- Dashboard cập nhật khi dữ liệu tồn kho thay đổi.
- Không cần tải lại trang.
- Có thể theo dõi dữ liệu từ nhiều thiết bị.

**Priority:** High


### US-16 – Quản lý vị trí kho

**User Story**

Là quản lý kho, tôi muốn quản lý các vị trí lưu trữ hàng hóa để kiểm soát việc sắp xếp sản phẩm trong kho.

**Acceptance Criteria**
- Quản lý được các khu vực/vị trí kho.
- Mỗi vị trí có mã định danh.
- Sản phẩm có thể được liên kết với vị trí.

**Priority:** Medium


### US-17 – Xem báo cáo nhập/xuất/tồn

**User Story**

Là quản lý kho, tôi muốn xem báo cáo nhập - xuất - tồn để đánh giá tình trạng và biến động của kho.

**Acceptance Criteria**
- Có báo cáo nhập kho.
- Có báo cáo xuất kho.
- Có báo cáo tồn kho.
- Dữ liệu báo cáo được lấy từ dữ liệu thực tế của hệ thống.

**Priority:** Medium
