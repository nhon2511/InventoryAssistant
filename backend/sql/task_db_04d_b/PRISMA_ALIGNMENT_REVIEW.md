# Prisma alignment — reviewable proposal, chưa sửa schema

File `backend/prisma/schema.prisma` hiện validate được nhưng mô tả vài quan hệ khác Cloud. Những thay đổi sau chỉ áp dụng sau khi Owner duyệt candidate SQL và NestJS write path, không chạy Prisma Migrate/db push.

```diff
 model Profile {
-  id String @id @default(uuid()) @db.Uuid
+  id String @id @db.Uuid
-  createdOrders WarehouseOrder[] @relation("CreatedOrders")
-  approvedOrders WarehouseOrder[] @relation("ApprovedOrders")
-  stockLedgers StockLedger[]
 }
 model InventoryItem {
-  product Product @relation(fields: [productId], references: [id], onDelete: Restrict)
-  location Location @relation(fields: [locationId], references: [id], onDelete: Restrict)
+  product Product @relation(fields: [productId], references: [id], onDelete: Cascade)
+  location Location @relation(fields: [locationId], references: [id], onDelete: Cascade)
+  stockLedgers StockLedger[]
 }
 model WarehouseOrder {
-  creator Profile? @relation("CreatedOrders", fields: [createdBy], references: [id], onDelete: SetNull)
-  approver Profile? @relation("ApprovedOrders", fields: [approvedBy], references: [id], onDelete: SetNull)
   // createdBy and approvedBy remain nullable UUID scalars; both FKs target
   // auth.users, which is Supabase-managed and is not modeled in this schema.
 }
 model StockLedger {
+  inventoryItemId String @map("inventory_item_id") @db.Uuid
+  inventoryItem InventoryItem @relation(fields: [inventoryItemId], references: [id], onDelete: Restrict)
-  creator Profile? @relation(fields: [createdBy], references: [id], onDelete: Restrict)
   // createdBy remains an immutable actor UUID, without a physical FK.
+  @@index([inventoryItemId, createdAt(sort: Desc), id(sort: Desc)], map: "stock_ledger_item_history_idx")
 }
```

`StockLedger` indexes must be reconciled with actual SQL: current single-column product/location/createdAt indexes are not created by this candidate; candidate adds item history and product/location history plus order index. Map or remove obsolete `@@index` declarations in the eventual Prisma patch. The partial `warehouse_orders_approved_by_idx` cannot be represented as an ordinary Prisma `@@index` without drift; retain the SQL index as database-owned and document it. `IdempotencyKey` fields and composite PK align with the candidate. Prisma does not encode CHECK, RLS, triggers, or grants; do not infer database readiness from `prisma validate`.

FK deletion semantics on existing `inventory_items` stay unchanged in this task. Once ledger rows exist, its `RESTRICT` FK can block deletion of an inventory item, product, location or order; Owner must approve archival/retention behavior before Cloud deployment.
