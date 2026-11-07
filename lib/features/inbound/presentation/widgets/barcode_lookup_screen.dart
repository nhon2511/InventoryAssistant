import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wms/core/preview/preview_mode.dart';
import 'package:smart_wms/core/widgets/scanner_back_button.dart';
import 'package:smart_wms/core/widgets/workspace_layout.dart';
import 'package:smart_wms/features/inbound/presentation/widgets/camera_scan_dialog.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/inventory_workspace_controller.dart';

class BarcodeLookupScreen extends ConsumerStatefulWidget {
  const BarcodeLookupScreen({super.key});
  @override
  ConsumerState<BarcodeLookupScreen> createState() =>
      _BarcodeLookupScreenState();
}

class _BarcodeLookupScreenState extends ConsumerState<BarcodeLookupScreen> {
  final input = TextEditingController();
  bool busy = false;
  String? error;
  Product? product;
  String source = 'Nhập thủ công';
  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: const ScannerBackButton(),
      title: const Text('Tra mã hàng'),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: ListView(
          padding: workspacePadding(context),
          children: [
            const Text(
              'Tra cứu sản phẩm qua repository. Tra mã không ghi nhận nhập/xuất hoặc thay đổi tồn.',
            ),
            const SizedBox(height: 20),
            TextField(
              controller: input,
              decoration: const InputDecoration(
                labelText: 'Mã vạch sản phẩm',
                prefixIcon: Icon(Icons.qr_code),
              ),
              onSubmitted: (_) {
                if (!busy) lookup();
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: busy ? null : lookup,
                  child: Text(busy ? 'Đang tra...' : 'Tra mã thủ công'),
                ),
                OutlinedButton.icon(
                  onPressed: busy || !CameraScanDialog.supported
                      ? null
                      : () async {
                          final code = await showDialog<String>(
                            context: context,
                            builder: (_) => const CameraScanDialog(),
                          );
                          if (code != null && mounted) {
                            input.text = code;
                            source = 'Camera';
                            await lookup();
                          }
                        },
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Camera'),
                ),
                if (ref.watch(frontendPreviewProvider))
                  OutlinedButton(
                    onPressed: busy
                        ? null
                        : () {
                            input.text = '893000000001';
                            source = 'Mô phỏng (fixture)';
                            lookup();
                          },
                    child: const Text('Mô phỏng mã mẫu'),
                  ),
                TextButton(
                  onPressed: () => context.push('/ocr-scan'),
                  child: const Text('OCR / số lô'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Nguồn: $source'),
            const Text(
              'Camera có UI plugin thực tế; quyền và khả năng nhận mã cần kiểm chứng trên thiết bị.',
            ),
            if (busy) const LinearProgressIndicator(),
            if (error != null)
              Column(
                children: [
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  TextButton(onPressed: lookup, child: const Text('Thử lại')),
                ],
              ),
            if (product != null)
              Card(
                child: ListTile(
                  title: Text(product!.name),
                  subtitle: Text(
                    '${product!.sku} · ${product!.unit}\nMã vạch: ${product!.barcode}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/products/${product!.id}'),
                ),
              ),
            if (!busy && error == null && product == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Nhập hoặc quét mã để xem kết quả.'),
              ),
          ],
        ),
      ),
    ),
  );
  Future<void> lookup() async {
    if (busy) return;
    if (input.text.trim().isEmpty) {
      setState(() => error = 'Vui lòng nhập mã vạch.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
      product = null;
    });
    try {
      final result = await ref.read(readInventoryProvider).barcode(input.text);
      if (!mounted) return;
      result.fold(
        (_) => setState(
          () => error = 'Không tìm thấy sản phẩm hoặc chưa tải được dữ liệu. Kiểm tra mã và thử lại.',
        ),
        (p) => setState(() => product = p),
      );
    } on Exception {
      if (mounted) {
        setState(() => error = 'Không tra được mã. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
