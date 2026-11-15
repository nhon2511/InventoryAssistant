import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/widgets/async_panel.dart';
import 'package:smart_wms/core/widgets/confirm_dialog.dart';
import 'package:smart_wms/core/widgets/workspace_layout.dart';
import 'package:smart_wms/features/auth/presentation/controllers/auth_controller.dart';
import 'package:smart_wms/features/auth/presentation/states/auth_state.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/inbound/presentation/controllers/batch_scanner_controller.dart';
import 'package:smart_wms/features/inventory/domain/entities/location.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/inventory_workspace_controller.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/location_controller.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/product_controller.dart';
import 'package:smart_wms/features/orders/presentation/controllers/order_workspace_controller.dart';
import 'package:uuid/uuid.dart';

/// Also used for editable AI draft previews. Nothing is saved on entry.
class OrderFormScreen extends ConsumerStatefulWidget {
  const OrderFormScreen({
    required this.type,
    super.key,
    this.initialItems = const [],
    this.initialNote,
  });
  final OrderType type;
  final List<WarehouseOrderItem> initialItems;
  final String? initialNote;
  @override
  ConsumerState<OrderFormScreen> createState() => _OrderFormScreenState();
}

class OrderExitGuard {
  Future<bool> Function()? confirm;
}

final orderExitGuardProvider = Provider<OrderExitGuard>(
  (ref) => OrderExitGuard(),
);

Future<bool> confirmOrderExit(BuildContext context) async =>
    await ProviderScope.containerOf(context)
        .read(orderExitGuardProvider)
        .confirm
        ?.call() ??
    true;

class _OrderFormScreenState extends ConsumerState<OrderFormScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController note;
  late final List<_Line> lines;
  final requestId = const Uuid().v4();
  bool busy = false;
  bool submitted = false;
  String? error;
  late final OrderExitGuard exitGuard;
  late final String initialFingerprint;
  bool leaveAllowed = false;
  String get fingerprint =>
      '${note.text}|${lines.map((line) => '${line.productId}:${line.locationId}:${line.quantity.text}:${line.lotNumber.text}:${line.expiryDate.text}').join('|')}';
  Future<bool> confirmExit() async {
    if (leaveAllowed) return true;
    if (busy) return false;
    if (fingerprint == initialFingerprint && widget.initialItems.isEmpty) {
      return true;
    }
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Rời phiếu chưa lưu?',
      content: 'Các thay đổi chưa lưu sẽ bị bỏ.',
      confirmText: 'Rời phiếu',
      cancelText: 'Tiếp tục nhập',
    );
    if (confirmed) leaveAllowed = true;
    return confirmed;
  }

  @override
  void initState() {
    super.initState();
    note = TextEditingController(text: widget.initialNote);
    lines = widget.initialItems.isEmpty
        ? [_Line()]
        : widget.initialItems
              .map(
                (i) => _Line(
                  productId: i.productId,
                  locationId: i.locationId,
                  quantity: i.expectedQuantity.toString(),
                  lotNumber: i.lotNumber ?? '',
                  expiryDate: i.expiryDate == null
                      ? ''
                      : DateFormat('dd/MM/yyyy').format(i.expiryDate!),
                ),
              )
              .toList();
    initialFingerprint = fingerprint;
    exitGuard = ref.read(orderExitGuardProvider)..confirm = confirmExit;
  }

  @override
  void dispose() {
    exitGuard.confirm = null;
    note.dispose();
    for (final line in lines) {
      line.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final products = ref.watch(productControllerProvider);
    final locations = ref.watch(locationControllerProvider);
    final stock = ref.watch(stockSnapshotProvider);
    final available = ref.watch(orderWorkflowRepositoryProvider).available;
    return Scaffold(
      bottomNavigationBar: SafeArea(
        top: false,
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: busy ? null : cancel,
                  child: const Text('Hủy'),
                ),
                FilledButton.icon(
                  onPressed:
                      busy ||
                          auth is! AuthAuthenticated ||
                          !products.hasValue ||
                          !locations.hasValue
                      ? null
                      : save,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined, size: 20),
                  label: Text(
                    busy
                        ? 'Đang lưu...'
                        : available
                        ? 'Xác nhận lưu nháp'
                        : 'Kiểm tra phiếu nháp',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: AsyncPanel(
        value: products,
        onRetry: () => ref.invalidate(productControllerProvider),
        builder: (ps) => AsyncPanel(
          value: locations,
          onRetry: () => ref.invalidate(locationControllerProvider),
          builder: (ls) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Form(
                key: form,
                autovalidateMode: submitted
                    ? AutovalidateMode.always
                    : AutovalidateMode.disabled,
                child: ListView(
                  padding: workspacePadding(context),
                  children: [
                    WorkspaceHeader(
                      title: widget.type == OrderType.inbound
                          ? 'Tạo phiếu nhập'
                          : 'Tạo phiếu xuất',
                      description: 'Lập phiếu nháp và kiểm tra các dòng hàng trước khi lưu.',
                      actions: [
                        OutlinedButton.icon(
                          onPressed: busy ? null : () => scanIntoOrder(ps),
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Quét mã'),
                        ),
                      ],
                    ),
                    Text(
                      'Thông tin phiếu',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: note,
                      enabled: !busy,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú (tùy chọn)',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Sản phẩm',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Lưu nháp không làm thay đổi tồn kho. Kiểm tra các dòng hàng trước khi xác nhận.',
                    ),
                    if (!available)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Chức năng lưu phiếu hiện chưa sẵn sàng. Bạn vẫn có thể kiểm tra thông tin đã nhập.',
                        ),
                      ),
                    for (var index = 0; index < lines.length; index++)
                      lineCard(lines[index], index, ps, ls),
                    OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () => setState(() => lines.add(_Line())),
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm dòng hàng'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${lines.length} dòng hàng',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...unitSummary(ps),
                    const SizedBox(height: 16),
                    if (widget.type == OrderType.outbound && !stock.hasValue)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chưa có dữ liệu tồn để kiểm tra xuất vượt tồn. Hãy tải lại tồn kho trước khi xử lý phiếu.',
                          ),
                          if (stock.hasError)
                            TextButton(
                              onPressed: () =>
                                  ref.invalidate(stockSnapshotProvider),
                              child: const Text('Thử tải tồn kho lại'),
                            ),
                        ],
                      ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget lineCard(
    _Line line,
    int index,
    List<Product> products,
    List<Location> locations,
  ) => Card(
    key: line.key,
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Dòng ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Xóa dòng',
                onPressed: busy
                    ? null
                    : () => setState(() {
                        lines.remove(line);
                        line.dispose();
                      }),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final fields = <Widget>[
                DropdownButtonFormField<String>(
                  initialValue: products.any((p) => p.id == line.productId)
                      ? line.productId
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Sản phẩm *'),
                  items: products
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            '${p.sku} · ${p.name}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: busy
                      ? null
                      : (v) => setState(() => line.productId = v),
                  menuMaxHeight: 320,
                  validator: (v) => v == null ? 'Chọn sản phẩm' : null,
                ),

                DropdownButtonFormField<String>(
                  initialValue: locations.any((l) => l.id == line.locationId)
                      ? line.locationId
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Vị trí *'),
                  items: locations
                      .map(
                        (l) => DropdownMenuItem(
                          value: l.id,
                          child: Text(l.displayLabel),
                        ),
                      )
                      .toList(),
                  onChanged: busy
                      ? null
                      : (v) => setState(() => line.locationId = v),
                  menuMaxHeight: 320,
                  validator: (v) => v == null ? 'Chọn vị trí' : null,
                ),

                TextFormField(
                  controller: line.quantity,
                  enabled: !busy,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Số lượng *'),
                  validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                      ? 'Nhập số nguyên lớn hơn 0'
                      : null,
                ),
              ];
              final lotAndExpiry = LayoutBuilder(
                builder: (context, metadataConstraints) {
                  final lotField = TextFormField(
                    controller: line.lotNumber,
                    enabled: !busy,
                    decoration: const InputDecoration(
                      labelText: 'Số lô (tùy chọn)',
                    ),
                  );
                  final expiryField = TextFormField(
                    controller: line.expiryDate,
                    enabled: !busy,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Hạn sử dụng (tùy chọn)',
                      hintText: 'dd/MM/yyyy',
                      suffixIcon: IconButton(
                        tooltip: 'Chọn hạn sử dụng',
                        onPressed: busy ? null : () => selectExpiryDate(line),
                        icon: const Icon(Icons.calendar_month_outlined),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      return _tryParseExpiryDate(value) == null
                          ? 'Chọn ngày hợp lệ'
                          : null;
                    },
                  );
                  if (metadataConstraints.maxWidth < 560) {
                    return Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: busy
                                ? null
                                : () => parseLabelForLine(line),
                            icon: const Icon(Icons.document_scanner_outlined),
                            label: const Text('Nhập số lô từ văn bản nhãn'),
                          ),
                        ),
                        lotField,
                        const SizedBox(height: 12),
                        expiryField,
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton.icon(
                        onPressed: busy ? null : () => parseLabelForLine(line),
                        icon: const Icon(Icons.document_scanner_outlined),
                        label: const Text('Nhập số lô từ văn bản nhãn'),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: lotField),
                          const SizedBox(width: 12),
                          Expanded(child: expiryField),
                        ],
                      ),
                    ],
                  );
                },
              );
              final unit =
                  products
                      .where((p) => p.id == line.productId)
                      .firstOrNull
                      ?.unit ??
                  '—';
              if (constraints.maxWidth >= 800) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: fields[0]),
                        const SizedBox(width: 16),
                        Expanded(flex: 3, child: fields[1]),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: fields[2]),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 70,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Text(unit),
                          ),
                        ),
                      ],
                    ),
                    if (widget.type == OrderType.inbound) ...[
                      const SizedBox(height: 12),
                      lotAndExpiry,
                    ],
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final field in fields) ...[
                    field,
                    const SizedBox(height: 16),
                  ],
                  Text('Đơn vị: $unit'),
                  if (widget.type == OrderType.inbound) ...[
                    const SizedBox(height: 12),
                    lotAndExpiry,
                  ],
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
  List<Widget> unitSummary(List<Product> products) {
    final totals = <String, int>{};
    for (final line in lines) {
      final product = products.where((p) => p.id == line.productId).firstOrNull;
      final quantity = int.tryParse(line.quantity.text) ?? 0;
      if (product != null && quantity > 0) {
        totals.update(
          product.unit,
          (value) => value + quantity,
          ifAbsent: () => quantity,
        );
      }
    }
    return [
      for (final entry in totals.entries) Text('${entry.value} ${entry.key}'),
    ];
  }

  Future<void> cancel() async {
    if (await confirmExit() && mounted) {
      leaveAllowed = true;
      context.go(widget.type == OrderType.inbound ? '/inbound' : '/outbound');
    }
  }

  Future<void> selectExpiryDate(_Line line) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _tryParseExpiryDate(line.expiryDate.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Chọn hạn sử dụng',
    );
    if (selected == null || !mounted) return;
    setState(() {
      line.expiryDate.text = DateFormat('dd/MM/yyyy').format(selected);
    });
  }

  DateTime? _tryParseExpiryDate(String value) {
    if (value.trim().isEmpty) return null;
    for (final format in [
      'dd/MM/yyyy',
      'd/M/yyyy',
      'dd-MM-yyyy',
      'd-M-yyyy',
      'dd.MM.yyyy',
      'd.M.yyyy',
      'dd/MM/yy',
      'd/M/yy',
    ]) {
      try {
        return DateFormat(format).parseStrict(value.trim());
      } on FormatException {
        continue;
      }
    }
    return DateTime.tryParse(value.trim());
  }

  Future<void> parseLabelForLine(_Line line) async {
    final values = await context.push<Map<String, String>>(
      '/ocr-scan',
      extra: 'inbound-line',
    );
    if (!mounted || values == null) return;
    final rawExpiry = values['expiryDate'];
    final parsedExpiry = rawExpiry == null
        ? null
        : _tryParseExpiryDate(rawExpiry);
    setState(() {
      final lot = values['lotNumber'];
      if (lot != null) line.lotNumber.text = lot;
      if (parsedExpiry != null) {
        line.expiryDate.text = DateFormat('dd/MM/yyyy').format(parsedExpiry);
      }
    });
    if (rawExpiry != null && parsedExpiry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã nhận số lô. Hãy chọn lại hạn sử dụng bằng lịch.'),
        ),
      );
    }
  }

  Future<void> scanIntoOrder(List<Product> products) async {
    ref.read(batchScannerControllerProvider.notifier).reset();
    final scanned = await context.push<Map<String, int>>(
      '/batch-scan',
      extra: 'order-scan',
    );
    if (!mounted || scanned == null || scanned.isEmpty) return;

    final unmatched = <String>[];
    setState(() {
      for (final entry in scanned.entries) {
        final product = products
            .where((candidate) => candidate.barcode == entry.key)
            .firstOrNull;
        if (product == null) {
          unmatched.add(entry.key);
          continue;
        }
        final existing = lines
            .where((line) => line.productId == product.id)
            .firstOrNull;
        if (existing == null) {
          lines.add(
            _Line(productId: product.id, quantity: entry.value.toString()),
          );
        } else {
          final current = int.tryParse(existing.quantity.text) ?? 0;
          existing.quantity.text = (current + entry.value).toString();
        }
      }
    });
    if (!mounted) return;
    final message = unmatched.isEmpty
        ? 'Đã thêm mã sản phẩm vào phiếu. Hãy chọn vị trí cho từng dòng.'
        : 'Đã thêm mã khớp; không tìm thấy ${unmatched.length} mã: ${unmatched.join(', ')}';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> save() async {
    if (busy) return;
    setState(() => submitted = true);
    if (lines.isEmpty) {
      setState(() => error = 'Thêm ít nhất một dòng sản phẩm.');
      return;
    }
    if (!(form.currentState?.validate() ?? false)) {
      final invalid = lines
          .where(
            (line) =>
                line.productId == null ||
                line.locationId == null ||
                (int.tryParse(line.quantity.text) ?? 0) <= 0,
          )
          .firstOrNull;
      final fieldContext = invalid?.key.currentContext;
      if (fieldContext != null) {
        await Scrollable.ensureVisible(fieldContext, alignment: .1);
      }
      return;
    }
    final auth = ref.read(authControllerProvider);
    if (auth is! AuthAuthenticated) return;
    final products = ref.read(productControllerProvider).value ?? [];
    final items = lines
        .map(
          (line) => WarehouseOrderItem(
            id: const Uuid().v4(),
            orderId: '',
            productId: line.productId ?? '',
            locationId: line.locationId,
            lotNumber:
                widget.type == OrderType.inbound &&
                    line.lotNumber.text.trim().isNotEmpty
                ? line.lotNumber.text.trim()
                : null,
            expiryDate: widget.type == OrderType.inbound
                ? _tryParseExpiryDate(line.expiryDate.text)
                : null,
            productName: products
                .where((p) => p.id == line.productId)
                .firstOrNull
                ?.name,
            expectedQuantity: int.parse(line.quantity.text),
            actualQuantity: 0,
          ),
        )
        .toList();
    setState(() {
      busy = true;
      error = null;
    });
    final result = await ref
        .read(orderWorkspaceProvider)
        .save(
          type: widget.type,
          profile: auth.profile,
          items: items,
          requestId: requestId,
          stock: ref.read(stockSnapshotProvider).value,
          note: note.text.trim(),
        );
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        busy = false;
        error = ref.read(orderWorkflowRepositoryProvider).available
            ? f.message
            : 'Chức năng lưu phiếu hiện chưa sẵn sàng. Thông tin đã nhập vẫn được giữ lại.';
      }),
      (order) {
        leaveAllowed = true;
        ref.invalidate(ordersProvider(widget.type));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu phiếu nháp. Tồn kho chưa thay đổi.'),
          ),
        );
        context.go(
          '${widget.type == OrderType.inbound ? "/inbound" : "/outbound"}/${order.id}',
        );
      },
    );
  }
}

class _Line {
  _Line({
    this.productId,
    this.locationId,
    String quantity = '',
    String lotNumber = '',
    String expiryDate = '',
  }) : quantity = TextEditingController(text: quantity),
       lotNumber = TextEditingController(text: lotNumber),
       expiryDate = TextEditingController(text: expiryDate);
  String? productId;
  String? locationId;
  final TextEditingController quantity;
  final TextEditingController lotNumber;
  final TextEditingController expiryDate;
  final key = GlobalKey();
  void dispose() {
    quantity.dispose();
    lotNumber.dispose();
    expiryDate.dispose();
  }
}
