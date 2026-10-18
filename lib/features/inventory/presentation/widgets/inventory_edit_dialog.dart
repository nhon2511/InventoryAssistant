import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wms/features/auth/presentation/controllers/auth_controller.dart';
import 'package:smart_wms/features/auth/presentation/states/auth_state.dart';
import 'package:smart_wms/features/inventory/domain/entities/location.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/inventory_workspace_controller.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/location_controller.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/product_controller.dart';
import 'package:uuid/uuid.dart';

class InventoryEditDialog extends ConsumerStatefulWidget {
  const InventoryEditDialog({
    super.key,
    this.product,
    this.location,
    this.isLocation = false,
  });
  final Product? product;
  final Location? location;
  final bool isLocation;
  @override
  ConsumerState<InventoryEditDialog> createState() =>
      _InventoryEditDialogState();
}

class _InventoryEditDialogState extends ConsumerState<InventoryEditDialog> {
  final form = GlobalKey<FormState>();
  late final List<TextEditingController> fields;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    final p = widget.product;
    final l = widget.location;
    fields =
        (widget.isLocation
                ? [
                    l?.zoneCode ?? '',
                    l?.aisleCode ?? '',
                    l?.rackCode ?? '',
                    l?.binCode ?? '',
                    l?.locationBarcode ?? '',
                    l?.maxCapacityKg?.toString() ?? '',
                  ]
                : [
                    p?.name ?? '',
                    p?.sku ?? '',
                    p?.barcode ?? '',
                    p?.unit ?? '',
                    '${p?.minSafetyStock ?? 0}',
                    p?.description ?? '',
                  ])
            .map((text) => TextEditingController(text: text))
            .toList();
  }

  @override
  void dispose() {
    for (final f in fields) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.isLocation
        ? [
            'Khu (Zone)',
            'Dãy (Aisle)',
            'Kệ (Rack)',
            'Ô (Bin)',
            'Mã vạch vị trí',
            'Sức chứa kg (tùy chọn)',
          ]
        : [
            'Tên sản phẩm',
            'SKU',
            'Mã vạch',
            'Đơn vị',
            'Tồn an toàn',
            'Mô tả (tùy chọn)',
          ];
    final available = ref
        .watch(inventoryMaintenanceRepositoryProvider)
        .available;
    return AlertDialog(
      title: Text(
        widget.isLocation ? 'Thông tin vị trí' : 'Thông tin sản phẩm',
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!available)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Có thể xem và kiểm tra form. Lưu chưa khả dụng: chờ contract backend.',
                    ),
                  ),
                for (var i = 0; i < fields.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      controller: fields[i],
                      decoration: InputDecoration(labelText: labels[i]),
                      keyboardType: i == (widget.isLocation ? 5 : 4)
                          ? TextInputType.number
                          : TextInputType.text,
                      validator: (v) {
                        if (i < 5 && (v == null || v.trim().isEmpty)) {
                          return 'Trường bắt buộc';
                        }
                        if (!widget.isLocation &&
                            i == 4 &&
                            (int.tryParse(v ?? '') == null ||
                                int.parse(v!) < 0)) {
                          return 'Nhập số nguyên không âm';
                        }
                        if (widget.isLocation &&
                            i == 5 &&
                            v!.isNotEmpty &&
                            (double.tryParse(v) == null ||
                                !double.parse(v).isFinite ||
                                double.parse(v) <= 0)) {
                          return 'Nhập sức chứa lớn hơn 0';
                        }
                        return null;
                      },
                    ),
                  ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: busy ? null : save,
          child: Text(
            busy
                ? 'Đang lưu...'
                : available
                ? 'Lưu'
                : 'Kiểm tra form',
          ),
        ),
      ],
    );
  }

  Future<void> save() async {
    if (busy) return;
    if (!form.currentState!.validate()) return;
    final auth = ref.read(authControllerProvider);
    if (auth is! AuthAuthenticated || !auth.profile.role.isAdmin) {
      setState(() => error = 'Chỉ Admin được quản lý dữ liệu.');
      return;
    }
    if (!ref.read(inventoryMaintenanceRepositoryProvider).available) {
      setState(() => error = 'Form hợp lệ. Chưa lưu: chờ tích hợp backend.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    final values = fields.map((f) => f.text.trim()).toList();
    final usecase = ref.read(maintainInventoryProvider);
    final result = widget.isLocation
        ? await usecase.saveLocation(
            Location(
              id: widget.location?.id ?? const Uuid().v4(),
              zoneCode: values[0],
              aisleCode: values[1],
              rackCode: values[2],
              binCode: values[3],
              locationBarcode: values[4],
              maxCapacityKg: double.tryParse(values[5]),
            ),
            auth.profile.role,
          )
        : await usecase.saveProduct(
            Product(
              id: widget.product?.id ?? const Uuid().v4(),
              name: values[0],
              sku: values[1],
              barcode: values[2],
              unit: values[3],
              minSafetyStock: int.parse(values[4]),
              description: values[5],
            ),
            auth.profile.role,
          );
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        error = f.message;
        busy = false;
      }),
      (_) {
        ref
          ..invalidate(productControllerProvider)
          ..invalidate(locationControllerProvider);
        if (widget.product != null) {
          ref.invalidate(productDetailProvider(widget.product!.id));
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đã lưu dữ liệu.')));
        Navigator.pop(context);
      },
    );
  }
}
