# TASK-DB-04D-B7 — Supabase integration test readiness

Ngày 13/11/2026. Branch `feature/backend-nestjs-init`; tracked tree đầu task sạch. Chỉ chuẩn bị code/test và đọc metadata backup cục bộ. **Không kết nối Cloud, chạy `test:db`, migration, restore, DDL/DML, hoặc đổi Flutter/AppModule.** Năm SQL untracked trong `supabase/migrations/` và tài liệu Owner untracked giữ nguyên.

## 1. Files changed

| File | Mục đích |
| --- | --- |
| `backend/test/db-integration/target.ts` + `target.spec.ts` | Chốt test project allowlist, Dev ref khác, direct host/port/db, TLS, admin/backend roles và test actor; kiểm guard hoàn toàn offline. |
| `backend/vitest.config.db.ts`, `backend/package.json` | Script riêng `npm run test:db`; chỉ nạp `*.dbtest.ts`, fail trước khi test file chạy nếu thiếu approval/target. **B7 không chạy script này.** |
| `backend/test/db-integration/harness.ts`, `inventory.dbtest.ts` | Preflight identity PG17/roles/schema; fixture UUID độc lập; rollback-only real SQL tests và TODO concurrency. |
| `backend/test/db-integration/candidate-static.spec.ts` | Static assertions cho staging 001/002/role patch; không parse/execute SQL trên DB. |
| `backend/sql/task_db_04d_b7/order_item_lock_role_patch_candidate.sql` | **Fragment chưa chạy** cho thiếu quyền/policy khóa order lines; cần Owner duyệt và hợp nhất vào một canonical 001. |
| Ba unit test B4/B6 | Sửa typings của mock để full `tsc --noEmit` kiểm được test source. |
| Báo cáo này | Test architecture, inventory identity, recovery và release gates. |

## 2. Test architecture và target isolation

`test:db` không fallback `DATABASE_URL`/`DIRECT_URL`. Bắt buộc khai báo riêng `DATABASE_TEST_URL`, `DATABASE_TEST_BACKEND_URL`, `DATABASE_TEST_PROJECT_REF`, `DATABASE_DEV_PROJECT_REF`, `DATABASE_TEST_ALLOWED_REFS`, `DATABASE_TEST_ACTOR_ID`, `DATABASE_TEST_APPROVED=YES`. Không log URL hoặc credential. Pure guard yêu cầu 20 ký tự project ref, ref test nằm trong allowlist và khác Dev ref, URL trỏ **đúng** `db.<test-ref>.supabase.co:5432/postgres`, `sslmode=require&sslaccept=strict`, admin login `postgres`, backend login `wms_backend`, hai URL khác nhau. Đây là hai tham số của connector Prisma v6 hiện tại: `require` bắt buộc TLS và `strict` tránh mặc định chấp nhận certificate không hợp lệ theo [Prisma v6 PostgreSQL connector docs](https://www.prisma.io/docs/orm/v6/overview/databases/postgresql). Chưa kết nối thật để chứng minh chain/hostname verification với Supabase; nếu TLS fail phải dừng, không nới guard. Chỉ hỗ trợ direct connection; nếu Owner cần pooler, phải thiết kế và duyệt guard khác. Owner cung cấp actor UUID test-only đã tạo trong `auth.users` của project cách ly; harness không tạo Auth user.

Khi Owner chạy riêng trong task được duyệt, preflight đầu tiên là transaction READ ONLY kiểm `current_database=postgres`, `current_user=postgres`, `server_version_num` thuộc PG17, actor test tồn tại, ledger/keys đã được áp dụng; sau đó kiểm kết nối `wms_backend` đúng role. Nếu sai, throw trước fixture. Host/ref ở URL là bằng chứng target từ cấu hình; metadata SQL không trả project ref có thể kiểm chứng độc lập, nên Operator vẫn phải đối chiếu ref trong Supabase Dashboard/Connect và Dev ref trước khi phê duyệt. Không đọc bản ghi Auth, chỉ `EXISTS` theo UUID test-only.

Fixture tạo product/location/inventory/order/line với UUID/code ngẫu nhiên trong outer transaction, rồi ép rollback. Điều này giữ các bài kiểm tra một kết nối độc lập và không để lại ledger audit row. Service/adapter được gọi qua proxy truyền **cùng Prisma transaction client**; kiểm SQL thực nhưng **không** chứng minh commit của adapter riêng, hai kết nối hoặc backend role có thể ghi. Nhóm concurrency có `it.todo` vì cần committed fixture và test project có cơ chế reset an toàn; không được coi TODO là PASS. `stock_ledger` append-only chặn DELETE/TRUNCATE cleanup, nên không dùng cleanup phá trigger trên test project. Owner cần disposable project hoặc approved reset/restore riêng cho các test durable. Mọi kết nối/ghi tương lai chỉ trong test target đã phê duyệt.

## 3. PostgreSQL test cases

| Case | Harness hiện có | Trạng thái B7 |
| --- | --- | --- |
| 1. Apply canonical schema | Preflight đòi 001 đã áp dụng; **không** tự apply. Owner cần một canonical 001 đã duyệt và test-project execution task riêng. | NOT RUN / BLOCKED |
| 2. FK/CHECK | Catalog asserts + CHECK-violating ledger insert và orphan order-line FK insert, đều rollback. | NOT RUN |
| 3. INSERT ledger | Confirmation SQL thật trong rollback transaction, assert delta/balance/order. | NOT RUN |
| 4. Append-only | Trigger catalog + UPDATE bị từ chối; DELETE/TRUNCATE chưa test vì không tác động shared ledger. | NOT RUN |
| 5. RLS/ACL role | `has_table_privilege` cho anon/authenticated; login backend; lock quyền theo role. PostgREST client behavior chưa test. | NOT RUN |
| 6. SELECT FOR UPDATE | Adapter khóa order, lines, inventory trong rollback transaction; backend role lock assertion không có fixture. | NOT RUN |
| 7. Rollback | Mọi fixture ép rollback; test CHECK/triggers gây lỗi được DB rollback. Lỗi line cuối qua service còn cần real test. | NOT RUN |
| 8. Simultaneous same key | TODO, cần hai connections + commit/teardown. | NOT RUN |
| 9. Hai request cùng phiếu | Same-key replay + key khác bị chặn tuần tự trong một transaction; concurrent TODO. | NOT RUN |
| 10. Hai phiếu cùng item | TODO committed fixture. | NOT RUN |
| 11. Serializable retry/lock timeout | TODO hai connections, fault injection có giới hạn. | NOT RUN |
| 12. Balance/ledger | Query stock/ledger và assert sau confirm trong rollback transaction. | NOT RUN |
| 13. Không double subtract/ledger | Replay và status guard tuần tự; concurrent + RPC bypass chưa test. | NOT RUN |
| 14. Client không ghi internal tables | ACL assertions + `SET LOCAL ROLE authenticated` thử INSERT key trong rollback transaction; PostgREST behavior TODO. | NOT RUN |

Không có PostgreSQL integration result PASS ở B7. `it.todo` thể hiện case còn phải implement/chạy khi có project disposable, approved schema/role, seed actor và reset plan.

## 4. Inventory identity và business-rule gaps

| Tình huống | Contract B6 hiện tại | Quyết định/test cần duyệt |
| --- | --- | --- |
| `lot_number NULL` | Đòi đúng một row `(product,location,NULL)`; nhiều row fail closed. | Unique hiện tại cho phép nhiều NULL; Owner chọn `NULLS NOT DISTINCT`, partial unique hoặc identity khác sau kiểm dữ liệu/drift. Test concurrent create trên PG17. |
| Lot không NULL | Đòi đúng một row, lot nguyên văn và expiry khớp. | Chuẩn hóa trim/case/collation và lot reuse/expiry policy; test duplicate. |
| New inventory item | B6 fail closed. | Chốt upsert/insert + lock/advisory lock/unique index, ledger opening balance và conflict handling. |
| Reserved | B6 không cho balance < reserved. | Audit mọi writer/reservation/RPC trước optional CHECK 002; test reserved concurrent. |
| Over/under receipt | `actual_quantity > 0`, không ép `actual <= expected`. | Owner xác nhận tolerance, partial receipt và status transitions; test cả hai. |
| Nhiều dòng cùng identity | B6 xử lý theo thứ tự cố định, một ledger event/dòng. | Xác nhận gộp hay giữ từng dòng và event uniqueness (`order_item_id` chưa có ở ledger). |

Không đổi unique constraint hoặc Flutter behavior trong B7.

## 5. Backup/recovery readiness

Chỉ kiểm metadata tại `D:\secure-review\backups\inventoryassistant_pre_migration_20261113.dump`: file 438.301 bytes, SHA-256 quan sát `D40E966DA05C61E8EAE93743BCDD36E068DC26E1D2B01983F37AE7DFFAA8BF27`, `pg_restore 18.3 --list` exit 0, **711 object entries / 726 TOC lines**. Lần báo Owner nêu 718 entries vẫn chưa đối chiếu phương pháp/manifest độc lập. Không đọc Auth/Vault rows hoặc in TOC/object data. Archive readable ≠ data complete ≠ restore verified. Chưa restore thử; backup không bao gồm bytes của Supabase Storage objects, globals/roles/external service state có thể cần quản lý riêng. [Supabase backup docs](https://supabase.com/docs/guides/platform/backups).

Restore verification plan riêng: Owner xác thực manifest/hash và source/PG version; provision disposable test project/roles/Auth dependencies; restore archive theo runbook đã rà soát; so sánh table inventory/count/checksums cho dữ liệu test hoặc manifest không nhạy cảm, constraints/indexes/RLS/functions/ACL; xác minh Auth/Storage metadata và phục hồi Storage object bytes qua backup riêng; đo RTO/RPO; xóa/reset project **chỉ bằng thao tác Owner duyệt**. Không restore trong B7. **Recovery readiness: BLOCKED.**

## 6. Migration release preparation và blocker mới

001 staging tạo ledger/keys/approved_by; B3 role fragment dự kiến hợp nhất **trước COMMIT** vào một canonical 001. 002 reserved CHECK là optional, chưa ghép vào release đầu. Preflight/postcheck scripts chỉ đọc, cần chạy trong task release được duyệt sau target verification. Năm migration SQL chưa track của Owner giữ nguyên; clean release checkout/worktree riêng phải loại chúng khỏi release set mà không xóa/sửa/stage file Owner. Không `supabase db push`, repair hay Prisma Migrate trong B7.

**Blocker quyền mới:** B6 dùng `SELECT ... FOR UPDATE` trên `warehouse_order_items`, nhưng B3 role fragment chỉ có SELECT và RLS SELECT cho bảng này. Theo [PostgreSQL 17 SELECT docs](https://www.postgresql.org/docs/17/sql-select.html), row locking cần UPDATE privilege trên ít nhất một cột; UPDATE RLS policy cũng cần xem xét theo [CREATE POLICY docs](https://www.postgresql.org/docs/17/sql-createpolicy.html). Patch staging B7 đề xuất `UPDATE(actual_quantity)` + UPDATE policy cho `wms_backend`. Đây là quyền ghi bổ sung có rủi ro, **không được chạy độc lập**; Owner cần duyệt hoặc đổi chiến lược khóa/giới hạn role và kiểm bằng PG17. Role grant có thể còn thiếu cho `idempotency_keys ON CONFLICT`/Prisma generated SQL, nên test với login thực là gate bắt buộc. Không tuyên bố canonical 001 sẵn sàng.

Clean release sequence đề xuất: Owner chốt một 001 tổng hợp đã review + role/lock patch → target test project được duyệt, có actor/credentials riêng và reset plan → apply 001 **chỉ trên test project** trong task riêng → chạy `npm run test:db` → kiểm postcheck/RLS/Flutter smoke → backup restore assurance → mới xem xét Cloud Development release task khác. Dừng ngay khi ref/host/version/role/schema/history/privilege khác kỳ vọng hoặc test nào FAIL.

## 7. Offline QA và approval gates

| Gate | Kết quả B7 |
| --- | --- |
| `npm run prisma:validate`, `npm run prisma:generate` | PASS/PASS, offline |
| `npm run lint`, `npm run build`, `npx tsc --noEmit -p tsconfig.json` | PASS/PASS/PASS |
| `npm run test`, `npm run test:e2e` | PASS 80/80 unit, PASS 6/6 mock E2E |
| SQL static unit checks, `git diff --check` | PASS 2/2 static assertions, PASS whitespace |
| `npm run test:db` | **NOT RUN** — chưa có test target/approval |

Owner cần cấp project test **khác Dev**, direct PG17 endpoint/certificate, allowlist/ref, test-only Auth actor, backend role credential, canonical 001 + role patch được duyệt, và phương án reset để chạy concurrency durable; không gửi password/URL vào chat hoặc Git. Cần xác nhận nguồn role/JWT B5, sáu RLS policies, RPC outbound và Storage recovery trước cutover. Next executable task là apply/test canonical 001 **trên isolated test project** với quyền riêng, sau đó mới đối chiếu integration outcomes; B7 dừng tại readiness.
