import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/core/enums/order_status.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/enums/user_role.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/auth/domain/entities/profile.dart';
import 'package:smart_wms/features/auth/domain/repositories/auth_repository.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/inbound/domain/repositories/inbound_repository.dart';
import 'package:smart_wms/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_wms/features/inventory/domain/entities/location.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';
import 'package:smart_wms/features/inventory/domain/repositories/inventory_maintenance_repository.dart';
import 'package:smart_wms/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:smart_wms/features/orders/domain/repositories/order_workflow_repository.dart';
import 'package:smart_wms/features/outbound/domain/repositories/outbound_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:uuid/uuid.dart';

/// Explicit in-memory fixtures. No Supabase initialization or network writes.
class PreviewRepository
    implements
        AuthRepository,
        InventoryRepository,
        InventoryMaintenanceRepository,
        InboundRepository,
        OutboundRepository,
        OrderWorkflowRepository {
  PreviewRepository({bool showcase = false}) {
    orders.addAll([
      WarehouseOrder(
        id: 'in-1',
        orderCode: 'PN-XEM-001',
        type: OrderType.inbound,
        status: OrderStatus.draft,
        createdBy: 'preview-staff',
        createdAt: DateTime.now(),
        note: 'Phiếu mẫu để duyệt; không cập nhật tồn.',
        items: const [
          WarehouseOrderItem(
            id: 'line-1',
            orderId: 'in-1',
            productId: 'p-1',
            productName: 'Găng tay bảo hộ',
            locationId: 'l-1',
            expectedQuantity: 12,
            actualQuantity: 0,
          ),
        ],
      ),
      WarehouseOrder(
        id: 'out-1',
        orderCode: 'PX-XEM-001',
        type: OrderType.outbound,
        status: OrderStatus.confirmed,
        createdBy: 'preview-staff',
        approvedBy: 'preview-admin',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        items: const [
          WarehouseOrderItem(
            id: 'line-2',
            orderId: 'out-1',
            productId: 'p-2',
            productName: 'Băng keo đóng thùng',
            locationId: 'l-2',
            expectedQuantity: 5,
            actualQuantity: 0,
          ),
        ],
      ),
      WarehouseOrder(
        id: 'other-1',
        orderCode: 'PN-XEM-002',
        type: OrderType.inbound,
        status: OrderStatus.completed,
        createdBy: 'preview-other',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ]);
    if (showcase) {
      products.add(
        const Product(
          id: 'p-long',
          barcode: '893000000004',
          sku: 'BH-004',
          name: 'Áo bảo hộ phản quang chống thấm nước dùng cho khu vực giao nhận hàng hóa ngoài trời',
          unit: 'cái',
          minSafetyStock: 0,
        ),
      );
      for (final status in [
        OrderStatus.confirmed,
        OrderStatus.processing,
        OrderStatus.cancelled,
      ]) {
        orders.add(
          WarehouseOrder(
            id: 'showcase-${status.name}',
            orderCode: 'PN-XEM-00${orders.length}',
            type: OrderType.inbound,
            status: status,
            createdBy: 'preview-staff',
            createdAt: DateTime.now().subtract(Duration(days: orders.length)),
            note: 'Nhận vật tư cho khu vực giao nhận hàng hóa. Kiểm tra tem nhãn, quy cách đóng gói và vị trí lưu kho trước khi xử lý.',
            items: orders.first.items,
          ),
        );
      }
    }
  }
  Profile? profile;
  final products = <Product>[
    const Product(
      id: 'p-1',
      sku: 'BH-001',
      barcode: '893000000001',
      name: 'Găng tay bảo hộ',
      unit: 'đôi',
      minSafetyStock: 20,
      description: 'Vật tư bảo hộ trong kho.',
    ),
    const Product(
      id: 'p-2',
      sku: 'DG-002',
      barcode: '893000000002',
      name: 'Băng keo đóng thùng',
      unit: 'cuộn',
      minSafetyStock: 30,
    ),
    const Product(
      id: 'p-3',
      sku: 'TH-003',
      barcode: '893000000003',
      name: 'Thùng carton 40 × 30',
      unit: 'cái',
      minSafetyStock: 50,
    ),
  ];
  final locations = <Location>[
    const Location(
      id: 'l-1',
      zoneCode: 'A',
      aisleCode: '01',
      rackCode: '01',
      binCode: '01',
      locationBarcode: 'LOC-A010101',
      maxCapacityKg: 500,
    ),
    const Location(
      id: 'l-2',
      zoneCode: 'B',
      aisleCode: '01',
      rackCode: '02',
      binCode: '01',
      locationBarcode: 'LOC-B010201',
      maxCapacityKg: 800,
    ),
  ];
  final stock = <InventoryItem>[
    const InventoryItem(
      id: 's-1',
      productId: 'p-1',
      productName: 'Găng tay bảo hộ',
      locationId: 'l-1',
      locationLabel: 'A-01-01-01',
      quantityOnHand: 80,
      quantityReserved: 10,
      lotNumber: 'LO-01',
    ),
    const InventoryItem(
      id: 's-2',
      productId: 'p-2',
      productName: 'Băng keo đóng thùng',
      locationId: 'l-2',
      locationLabel: 'B-01-02-01',
      quantityOnHand: 24,
      quantityReserved: 4,
    ),
    const InventoryItem(
      id: 's-3',
      productId: 'p-3',
      productName: 'Thùng carton 40 × 30',
      locationId: 'l-2',
      locationLabel: 'B-01-02-01',
      quantityOnHand: 120,
      quantityReserved: 0,
    ),
  ];
  final orders = <WarehouseOrder>[];
  final requests = <String, WarehouseOrder>{};
  final changes = StreamController<List<InventoryItem>>.broadcast();
  static const missing = ServerFailure(
    message: 'Không tìm thấy trong dữ liệu xem trước.',
  );
  @override
  bool get available => true;
  @override
  FutureEither<Profile> signIn({
    required String email,
    required String password,
  }) async {
    final role = email.startsWith('admin@')
        ? UserRole.admin
        : email.startsWith('manager@')
        ? UserRole.manager
        : UserRole.staff;
    profile = Profile(
      id: 'preview-${role.name}',
      fullName: role.isAdmin
          ? 'Admin xem trước'
          : role == UserRole.manager
          ? 'Quản lý xem trước'
          : 'Nhân viên xem trước',
      role: role,
      phoneNumber: '0900000000',
    );
    return Right(profile!);
  }

  @override
  FutureEither<Profile> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    profile = Profile(
      id: 'preview-staff',
      fullName: fullName,
      role: UserRole.staff,
      phoneNumber: phoneNumber,
    );
    return Right(profile!);
  }

  @override
  FutureVoid signOut() async {
    profile = null;
    return const Right(null);
  }

  @override
  FutureEither<Profile> getCurrentProfile() async => profile == null
      ? const Left(AuthFailure(message: 'Chưa đăng nhập xem trước.'))
      : Right(profile!);
  @override
  Stream<supabase.AuthState> get onAuthStateChange => const Stream.empty();
  @override
  FutureEither<List<Product>> getAllProducts() async =>
      Right(List.unmodifiable(products));
  @override
  FutureEither<Product> getProductById(String id) async {
    final p = products.where((p) => p.id == id).firstOrNull;
    return p == null ? const Left(missing) : Right(p);
  }

  @override
  FutureEither<Product> getProductByBarcode(String barcode) async {
    final p = products.where((p) => p.barcode == barcode).firstOrNull;
    return p == null ? const Left(missing) : Right(p);
  }

  @override
  FutureEither<List<Location>> getAllLocations() async =>
      Right(List.unmodifiable(locations));
  @override
  FutureEither<Location> getLocationByBarcode(String barcode) async {
    final l = locations.where((l) => l.locationBarcode == barcode).firstOrNull;
    return l == null ? const Left(missing) : Right(l);
  }

  @override
  FutureEither<List<InventoryItem>> getStockByProduct(String id) async =>
      Right(stock.where((s) => s.productId == id).toList());
  @override
  FutureEither<List<InventoryItem>> getAllInventoryItems() async =>
      Right(List.unmodifiable(stock));
  @override
  Stream<List<InventoryItem>> subscribeInventoryRealtime() async* {
    yield List.unmodifiable(stock);
    yield* changes.stream;
  }

  @override
  FutureEither<Product> saveProduct(Product product) async {
    if (products.any(
      (p) =>
          p.id != product.id &&
          (p.sku == product.sku || p.barcode == product.barcode),
    )) {
      return const Left(ServerFailure(message: 'SKU hoặc mã vạch đã tồn tại.'));
    }
    products.removeWhere((p) => p.id == product.id);
    products.add(product);
    return Right(product);
  }

  @override
  FutureVoid deleteProduct(String id) async {
    if (stock.any((s) => s.productId == id) ||
        orders.any((o) => o.items.any((i) => i.productId == id))) {
      return const Left(
        ServerFailure(
          message: 'Sản phẩm đang có tồn hoặc được tham chiếu trong phiếu.',
        ),
      );
    }
    products.removeWhere((p) => p.id == id);
    return const Right(null);
  }

  @override
  FutureEither<Location> saveLocation(Location location) async {
    if (locations.any(
      (l) =>
          l.id != location.id &&
          (l.displayLabel == location.displayLabel ||
              l.locationBarcode == location.locationBarcode),
    )) {
      return const Left(
        ServerFailure(message: 'Mã vị trí hoặc mã vạch đã tồn tại.'),
      );
    }
    locations.removeWhere((l) => l.id == location.id);
    locations.add(location);
    return Right(location);
  }

  @override
  FutureVoid deleteLocation(String id) async {
    if (stock.any((s) => s.locationId == id) ||
        orders.any((o) => o.items.any((i) => i.locationId == id))) {
      return const Left(
        ServerFailure(
          message: 'Vị trí đang có tồn hoặc được tham chiếu trong phiếu.',
        ),
      );
    }
    locations.removeWhere((l) => l.id == id);
    return const Right(null);
  }

  @override
  FutureEither<WarehouseOrder> saveDraft({
    required OrderType type,
    required String createdBy,
    required List<WarehouseOrderItem> items,
    required String requestId,
    String? note,
  }) async {
    if (requests.containsKey(requestId)) return Right(requests[requestId]!);
    final id = const Uuid().v4();
    final order = WarehouseOrder(
      id: id,
      orderCode:
          '${type == OrderType.inbound ? "PN" : "PX"}-XEM-${orders.length + 1}',
      type: type,
      status: OrderStatus.draft,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      note: note,
      items: items
          .map(
            (i) => WarehouseOrderItem(
              id: i.id,
              orderId: id,
              productId: i.productId,
              productName: i.productName,
              locationId: i.locationId,
              expectedQuantity: i.expectedQuantity,
              actualQuantity: 0,
            ),
          )
          .toList(),
    );
    orders.insert(0, order);
    requests[requestId] = order;
    return Right(order);
  }

  @override
  FutureEither<WarehouseOrder> review({
    required String orderId,
    required OrderStatus expectedStatus,
    required bool approve,
    required String reviewerId,
  }) async {
    final old = orders.where((o) => o.id == orderId).firstOrNull;
    if (old == null) return const Left(missing);
    if (old.status != expectedStatus) {
      return const Left(
        ServerFailure(message: 'Trạng thái đã thay đổi. Tải lại phiếu.'),
      );
    }
    final updated = WarehouseOrder(
      id: old.id,
      orderCode: old.orderCode,
      type: old.type,
      status: approve ? OrderStatus.confirmed : OrderStatus.cancelled,
      createdBy: old.createdBy,
      approvedBy: reviewerId,
      note: old.note,
      items: old.items,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
    orders[orders.indexOf(old)] = updated;
    return Right(updated);
  }

  @override
  FutureEither<List<WarehouseOrder>> getInboundOrders() async =>
      Right(orders.where((o) => o.type == OrderType.inbound).toList());
  @override
  FutureEither<List<WarehouseOrder>> getOutboundOrders() async =>
      Right(orders.where((o) => o.type == OrderType.outbound).toList());
  FutureEither<WarehouseOrder> _order(String id) async {
    final o = orders.where((o) => o.id == id).firstOrNull;
    return o == null ? const Left(missing) : Right(o);
  }

  @override
  FutureEither<WarehouseOrder> getInboundOrderById(String id) => _order(id);
  @override
  FutureEither<WarehouseOrder> getOutboundOrderById(String id) => _order(id);
  @override
  FutureEither<WarehouseOrder> createInboundOrder({String? note}) => saveDraft(
    type: OrderType.inbound,
    createdBy: profile?.id ?? '',
    items: [],
    requestId: const Uuid().v4(),
    note: note,
  );
  @override
  FutureEither<WarehouseOrder> createOutboundOrder({String? note}) => saveDraft(
    type: OrderType.outbound,
    createdBy: profile?.id ?? '',
    items: [],
    requestId: const Uuid().v4(),
    note: note,
  );
  @override
  FutureEither<WarehouseOrderItem> addScannedItem({
    required String orderId,
    required String productId,
    required int quantity,
    String? locationId,
    String? lotNumber,
    DateTime? expiryDate,
  }) async => const Left(
    ServerFailure(message: 'Dùng form phiếu nháp trong chế độ xem trước.'),
  );
  @override
  FutureEither<WarehouseOrder> confirmInboundOrder(String id) async =>
      const Left(ServerFailure(message: 'Xem trước không cập nhật tồn kho.'));
  @override
  FutureVoid confirmOutboundOrder(String id) async =>
      const Left(ServerFailure(message: 'Xem trước không cập nhật tồn kho.'));
  Future<void> dispose() => changes.close();
}
