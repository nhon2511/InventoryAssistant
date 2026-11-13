# Rollback và forward-fix (chỉ là kế hoạch)

Các SQL ở thư mục này chưa được thực thi. Trước mọi lần triển khai, Operator cần xác minh đúng Development target, history, backup có thể restore, quyền truy cập và đường ghi tồn kho. Không dùng file này làm lệnh tự động.

## Nếu thất bại trước COMMIT

Transaction của từng candidate sẽ rollback toàn bộ. Dừng release, lưu lỗi đã loại bỏ secrets, đối chiếu catalog. Không chạy lại cho đến khi nguyên nhân drift/lock/permission được xử lý và preflight khớp.

## Nếu đã COMMIT

Ưu tiên migration forward-fix mới với version mới qua Supabase history. Không sửa migration đã áp dụng. Tạm dừng use case ghi ledger/keys nếu chưa có quyền backend. Không tự `DROP` ledger, approved_by, constraint, hoặc `your_table`: ledger có thể là bằng chứng kiểm toán, cột có thể đã chứa giá trị. Nếu CHECK optional chặn luồng cũ, điều tra write path và dữ liệu trước khi Owner duyệt migration tháo riêng. Chỉ restore bản backup đã thử trên môi trường cô lập theo kế hoạch Owner duyệt; restore có thể ghi đè dữ liệu mới và cần downtime.

## Đầu ra kiểm chứng

Postcheck phải xác nhận bảng/cột/FK/index/trigger/RLS/ACL và không có client privilege/policy mới. Kiểm thử giao dịch NestJS gồm concurrent same-key/different-hash, retry, atomic inventory update + ledger insert, rollback khi lỗi; kiểm thử quyền Flutter và Auth. Chưa có integration test nào được chạy trong task này.
