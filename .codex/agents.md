# Hướng dẫn dành cho AI agent

## 1. Tổng quan kiến trúc và công nghệ

- **Sản phẩm chính:** Smart WMS, ứng dụng Flutter đa nền tảng (Android, iOS và Web), mã nguồn ứng dụng nằm trong `lib/`.
- **Ngôn ngữ và SDK:** Dart/Flutter. Phiên bản SDK được khai báo chính thức trong `pubspec.yaml`; hãy ưu tiên giá trị ở đó khi có khác biệt với README.
- **Kiến trúc:** Feature-first kết hợp Clean Architecture. Mỗi tính năng thường tách `presentation`, `domain` và `data`.
- **State management và điều hướng:** Riverpod với code generation; GoRouter.
- **Backend:** Supabase Auth, Postgres/PostgREST, Realtime và Edge Functions. Các tên bảng/RPC/function tập trung ở `lib/core/constants/app_constants.dart`.
- **Thư viện đáng chú ý:** `fpdart` cho `Either`, `freezed`/`json_serializable` cho model, `mobile_scanner` và Google ML Kit cho barcode/OCR, `speech_to_text`, `fl_chart`, `excel` và `pdf`.
- `package.json` chỉ khai báo `@supabase/supabase-js` và `dotenv` để hỗ trợ các script JavaScript ở thư mục gốc; không có scripts npm và đây không phải ứng dụng Node chính.
- PRD/README mô tả một số năng lực mục tiêu. Kiểm tra mã thực tế trước khi coi tính năng là đã triển khai. Repo hiện không có thư mục migration hoặc mã nguồn Edge Functions của Supabase; không tự giả định schema/backend đã được triển khai chỉ dựa vào tài liệu.

## 2. Lệnh hệ thống cốt lõi

Chạy tại thư mục gốc. Cần cài Flutter/Dart phù hợp với `pubspec.yaml` và tạo `.env` theo `.env.example` trước khi chạy ứng dụng.

```bash
# Cài dependencies Flutter
flutter pub get

# Chạy ứng dụng trên thiết bị được Flutter nhận diện
flutter run

# Chạy Flutter Web trên Chrome
flutter run -d chrome

# Build các nền tảng
flutter build apk
flutter build ios
flutter build web

# Kiểm thử và phân tích tĩnh
flutter test
flutter analyze

# Sinh/cập nhật mã Riverpod, Freezed và JSON
dart run build_runner build --delete-conflicting-outputs
```

`flutter build ios` cần môi trường macOS/Xcode. Không có `Makefile` hoặc npm scripts cho build/test/lint trong cấu hình hiện tại. Lệnh kiểm tra Supabase bằng Node trong `supabase.md` là script hỗ trợ riêng, không thay cho lệnh Flutter.

## 3. Cấu trúc thư mục chính

```text
lib/
├── app/                  # Cấu hình ứng dụng, router và theme
├── core/                 # Hằng số, enum, lỗi, network, use case, tiện ích và widget dùng chung
├── features/
│   ├── auth/             # Xác thực và hồ sơ người dùng
│   ├── inventory/        # Sản phẩm, vị trí, tồn kho và realtime
│   ├── inbound/          # Phiếu nhập, quét hàng và OCR
│   ├── outbound/         # Phiếu xuất, pick list và xác minh hàng
│   └── ai_assistant/     # Chat AI, phân tích intent và tra cứu tồn kho
├── bootstrap.dart        # Khởi tạo Flutter, cấu hình môi trường và Supabase
└── main.dart             # Điểm vào ứng dụng

assets/                   # Tài nguyên ảnh/icon
android/, ios/, web/      # Cấu hình và mã nền tảng Flutter
docs/                     # User stories và tài liệu dự án
test/                     # Unit test cho tiện ích, lỗi, enum và use case
```

Trong mỗi feature, `domain/` chứa entity, repository contract và use case; `data/` chứa datasource, model và repository implementation; `presentation/` chứa controller/state và widget/màn hình. Một vài feature có thể chưa có đủ cả ba lớp.

## 4. Quy chuẩn lập trình và lưu ý cho AI

- Giữ tổ chức **feature-first** và phân lớp hiện có. Không đặt truy vấn Supabase trực tiếp trong widget; đi qua datasource/repository/use case theo mẫu của feature liên quan.
- `domain/` không phụ thuộc Flutter UI hoặc Supabase. Repository trong domain là contract; implementation và chuyển đổi model/entity thuộc `data/`.
- Repository thường trả `FutureEither<T>` (`Either<Failure, T>`). Datasource ném exception phù hợp; repository chuyển exception thành `Failure`. Giữ nhất quán với mẫu hiện có và không nuốt lỗi.
- Dùng Riverpod generator cho provider/controller. Khi sửa file có `part '*.g.dart'`, chạy build_runner và cập nhật file sinh tương ứng; không chỉnh tay file `.g.dart`. Analyzer loại các file sinh khỏi kiểm tra.
- Dùng `snake_case.dart` cho tên file và `UpperCamelCase` cho kiểu Dart; tuân theo `very_good_analysis` được cấu hình trong `analysis_options.yaml`. Ưu tiên formatter Dart (`dart format`). Một số giới hạn lint đã được nới trong cấu hình; không tự áp đặt chúng như lỗi bắt buộc.
- Điều hướng qua GoRouter và các tên/path tập trung trong `lib/app/router/`. UI dùng theme chung trong `lib/app/theme/`; văn bản giao diện nên phù hợp ứng dụng tiếng Việt và localization hiện có.
- Không đưa secret/service-role key vào ứng dụng Flutter hoặc commit `.env`. Chỉ dùng cấu hình client phù hợp; bảo mật dữ liệu phải dựa trên chính sách RLS/backend, không chỉ dựa trên ẩn/hiện UI. `.env` đã được gitignore; `.env.example` là mẫu cấu hình.
- Nghiệp vụ nhập/xuất ảnh hưởng tồn kho phải được thực thi an toàn ở backend (transaction/RPC và kiểm tra quyền). Không cập nhật tồn kho kiểu read-then-write không nguyên tử từ client.
- Barcode/OCR/AI cần xử lý dữ liệu không hợp lệ và trường hợp thiếu tự tin. AI chỉ nên tạo bản nháp cho thao tác ghi; cần người dùng kiểm tra/xác nhận trước khi ghi dữ liệu.
- Không giả định TODO hoặc mô tả trong PRD/README đã được triển khai. Xác minh luồng trong mã và backend trước khi mở rộng; cập nhật tài liệu nếu trạng thái thực tế thay đổi.
- Trước khi sửa, kiểm tra `git status` và giữ nguyên thay đổi sẵn có của người dùng. Chỉ chỉnh đúng phạm vi yêu cầu; không xóa hoặc ghi đè thay đổi chưa commit.
- Khi thay đổi logic, cập nhật/viết test phù hợp trong `test/`; dùng `flutter test` và `flutter analyze` để xác minh khi được yêu cầu hoặc khi quy trình công việc cho phép.

## 5. Kiểm thử, phân tích và build

- Chạy từ thư mục gốc; chọn lệnh phù hợp với phần vừa sửa: `flutter test [đường_dẫn_test]`, `flutter test`, `flutter analyze`, hoặc `dart format --output=none --set-exit-if-changed lib test`.
- Build ứng dụng bằng `flutter build apk` hoặc `flutter build web` khi cần xác minh build. `flutter build ios` chỉ chạy được trên macOS có Xcode.
- Chỉ chạy code generation khi thay đổi nguồn có generator; dùng `dart run build_runner build --delete-conflicting-outputs`. Xem diff các file sinh và giữ đồng bộ với nguồn.
- `package.json` không có scripts; Node.js chỉ hỗ trợ các script Supabase riêng ở thư mục gốc. Không dùng `npm test`/`npm run build` như lệnh của ứng dụng Flutter. Các script Supabase hiện là tiện ích thử nghiệm, không phải bộ kiểm thử ứng dụng.
- Không chạy lệnh kiểm thử/build tốn thời gian nếu không cần cho yêu cầu; báo rõ lệnh đã chạy và kết quả. Không khẳng định test/build thành công nếu chưa thực sự chạy.

## 6. Review và phạm vi thay đổi

- Trước khi sửa, đọc `git status --short` và kiểm tra diff liên quan. Phân biệt thay đổi có sẵn của người dùng với thay đổi của tác vụ; không ghi đè, hoàn tác hoặc đưa các thay đổi không liên quan vào phạm vi.
- Sau khi sửa, xem `git diff` và kiểm tra file mới bằng `git status`. Rà soát lỗi logic, xử lý lỗi, dữ liệu đầu vào không hợp lệ, quyền truy cập, trạng thái bất đồng bộ và tác động nền tảng.
- Chỉ sửa file cần thiết. Không tự xóa/di chuyển file, commit, push, tạo PR, deploy hoặc thay đổi cấu hình backend khi chưa được yêu cầu rõ ràng.

## 7. Dependency, bảo mật và cấu hình

- Flutter dependency được quản lý trong `pubspec.yaml` và khóa phiên bản trong `pubspec.lock`; JavaScript dependency trong `package.json`/`package-lock.json`. Chỉ thêm/nâng/hạ dependency khi yêu cầu cần đến, ưu tiên thư viện hiện có và cập nhật lockfile bằng trình quản lý tương ứng.
- Không sửa file sinh (`*.g.dart`, `*.freezed.dart`) bằng tay. Không chạy lệnh tự động có thể xóa/ghi đè file ngoài phạm vi; đặc biệt kiểm tra tác động của tùy chọn `--delete-conflicting-outputs` trước khi codegen.
- Không đọc, in log, sao chép hoặc commit giá trị bí mật từ `.env`, khóa API, token hay thông tin xác thực. Dùng `.env.example` làm tham chiếu; không sửa `.env` thật. Chỉ dùng khóa Supabase công khai phù hợp phía client; không nhúng service-role key.
- Không coi ẩn/hiện giao diện là kiểm soát quyền. Xác minh giả định về RLS, RPC và Edge Functions từ mã/backend thực tế; tài liệu PRD không chứng minh backend đã triển khai.
- Với nhập/xuất làm thay đổi tồn kho, giữ thao tác ghi nguyên tử ở backend và yêu cầu xác nhận của người dùng cho nội dung AI/OCR chưa được kiểm chứng.

## 8. ECC Skills và công cụ

- Khi một ECC Skill có sẵn trong môi trường Codex phù hợp trực tiếp với tác vụ, có thể áp dụng hướng dẫn đó cùng với quy tắc repo này. Ưu tiên skill về Flutter/Dart, review, bảo mật hoặc kiểm thử khi thực sự liên quan.
- Không giả định skill/plugin nào đã được cài, không cài plugin/dependency để dùng skill, và không sao chép nguyên bộ quy tắc skill vào tài liệu dự án. Nếu hướng dẫn skill xung đột với yêu cầu người dùng hoặc cấu hình repo, ưu tiên yêu cầu người dùng và cấu hình repo.
