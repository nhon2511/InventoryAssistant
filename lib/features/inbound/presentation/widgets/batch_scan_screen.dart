import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_wms/core/widgets/scanner_back_button.dart';
import 'package:smart_wms/core/widgets/workspace_layout.dart';
import 'package:smart_wms/features/inbound/presentation/controllers/batch_scanner_controller.dart';
import 'package:smart_wms/features/inbound/presentation/widgets/camera_scan_dialog.dart';

/// A browser- and device-camera scan session for collecting barcode counts.
///
/// Counts stay in memory and are not an inventory receipt until a verified
/// receiving workflow is connected.
class BatchScanScreen extends ConsumerStatefulWidget {
  const BatchScanScreen({super.key, this.onApply});

  /// Returns the session's barcode counts to an order form when opened there.
  final ValueChanged<Map<String, int>>? onApply;

  @override
  ConsumerState<BatchScanScreen> createState() => _BatchScanScreenState();
}

class _BatchScanScreenState extends ConsumerState<BatchScanScreen> {
  final _manualCode = TextEditingController();
  late final MobileScannerController _camera;
  bool _cameraActive = false;
  bool _cameraFailed = false;
  String? _cameraMessage;
  DateTime? _lastReadAt;
  String? _lastReadValue;

  @override
  void initState() {
    super.initState();
    _camera = MobileScannerController(autoStart: false);
  }

  @override
  void dispose() {
    _manualCode.dispose();
    _camera.dispose();
    super.dispose();
  }

  Future<void> _startCamera() async {
    setState(() {
      _cameraFailed = false;
      _cameraMessage = null;
    });
    try {
      await _camera.start();
      if (mounted) setState(() => _cameraActive = true);
    } on Exception {
      if (!mounted) return;
      setState(() {
        _cameraActive = false;
        _cameraFailed = true;
        _cameraMessage = 'Không mở được camera. Hãy kiểm tra quyền camera và dùng HTTPS hoặc localhost.';
      });
    }
  }

  Future<void> _stopCamera() async {
    try {
      await _camera.stop();
    } on Exception {
      // Keep the screen usable if the browser has already stopped the camera.
    }
    if (mounted) setState(() => _cameraActive = false);
  }

  void _record(String rawValue, {bool fromCamera = false}) {
    final value = rawValue.trim();
    if (value.isEmpty) return;

    if (fromCamera) {
      final now = DateTime.now();
      if (value == _lastReadValue &&
          _lastReadAt != null &&
          now.difference(_lastReadAt!) < const Duration(milliseconds: 1200)) {
        return;
      }
      _lastReadValue = value;
      _lastReadAt = now;
    }
    ref.read(batchScannerControllerProvider.notifier).addBarcode(value);
  }

  void _recordManual() {
    final value = _manualCode.text.trim();
    if (value.isEmpty) return;
    _record(value);
    _manualCode.clear();
  }

  Future<void> _clearSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa phiên quét?'),
        content: const Text('Danh sách mã và số lượt quét sẽ được xóa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa phiên'),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && mounted) {
      ref.read(batchScannerControllerProvider.notifier).reset();
      _lastReadAt = null;
      _lastReadValue = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(batchScannerControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const ScannerBackButton(),
        title: const Text('Quét mã nhập hàng'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/barcode-lookup'),
            icon: const Icon(Icons.search),
            label: const Text('Tra một mã'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: ListView(
            padding: workspacePadding(context),
            children: [
              Text(
                'Quét liên tục hoặc nhập mã để đếm sản phẩm trong phiên hiện tại.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.push('/ocr-scan'),
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: const Text('OCR / số lô'),
                ),
              ),
              if (widget.onApply != null && session.scannedItems.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: FilledButton.icon(
                      onPressed: () => _applyScans(session.scannedItems),
                      icon: const Icon(Icons.playlist_add_check),
                      label: const Text('Đưa mã vào phiếu'),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const _LocalSessionNotice(),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricCard(
                    label: 'Mã khác nhau',
                    value: '${session.uniqueCount}',
                    icon: Icons.qr_code_2,
                  ),
                  _MetricCard(
                    label: 'Tổng lượt quét',
                    value: '${session.totalScans}',
                    icon: Icons.repeat,
                  ),
                  _MetricCard(
                    label: 'Mã vừa nhận',
                    value: session.lastScannedBarcode ?? '—',
                    icon: Icons.check_circle_outline,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final scanner = _buildScannerPanel(context);
                  final list = _buildSessionPanel(
                    context,
                    session.scannedItems,
                  );
                  if (constraints.maxWidth < 820) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [scanner, const SizedBox(height: 16), list],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: scanner),
                      const SizedBox(width: 16),
                      Expanded(flex: 5, child: list),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyScans(Map<String, int> items) async {
    if (_cameraActive) await _stopCamera();
    if (!mounted) return;
    widget.onApply!(Map<String, int>.unmodifiable(items));
  }

  Widget _buildScannerPanel(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Máy quét', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MobileScanner(
                      controller: _camera,
                      onDetect: (capture) {
                        for (final barcode in capture.barcodes) {
                          final value = barcode.rawValue;
                          if (value != null && value.trim().isNotEmpty) {
                            _record(value, fromCamera: true);
                            break;
                          }
                        }
                      },
                      errorBuilder: (context, error, child) => _CameraError(
                        message: 'Camera không sẵn sàng. Kiểm tra quyền camera, HTTPS hoặc localhost.',
                        onRetry: _startCamera,
                      ),
                    ),
                    if (!_cameraActive)
                      _CameraPlaceholder(
                        failed: _cameraFailed,
                        message: _cameraMessage,
                        supported: CameraScanDialog.supported,
                        onStart: _startCamera,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_cameraActive) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _stopCamera,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Tắt camera'),
            ),
          ],
          const Divider(height: 28),
          Text(
            'Nhập mã thủ công',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualCode,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Mã vạch sản phẩm',
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                  onSubmitted: (_) => _recordManual(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _recordManual,
                child: const Text('Ghi nhận'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildSessionPanel(BuildContext context, Map<String, int> items) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Danh sách đã quét',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  if (items.isNotEmpty)
                    TextButton.icon(
                      onPressed: _clearSession,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Xóa phiên'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(Icons.qr_code_scanner, size: 40),
                      SizedBox(height: 8),
                      Text('Chưa có mã nào trong phiên này.'),
                    ],
                  ),
                )
              else
                for (final entry in items.entries)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.inventory_2_outlined),
                    ),
                    title: SelectableText(entry.key),
                    subtitle: const Text('Mã vạch'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '× ${entry.value}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          tooltip: 'Xóa mã ${entry.key}',
                          onPressed: () => ref
                              .read(batchScannerControllerProvider.notifier)
                              .removeBarcode(entry.key),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      );
}

class _LocalSessionNotice extends StatelessWidget {
  const _LocalSessionNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.inventory_2_outlined),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Đây là bộ đếm tạm trong trình duyệt. Dữ liệu chưa được lưu thành phiếu nhập và không làm thay đổi tồn kho.',
          ),
        ),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: compact ? 300 : 190,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder({
    required this.failed,
    required this.message,
    required this.supported,
    required this.onStart,
  });

  final bool failed;
  final String? message;
  final bool supported;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            failed ? Icons.no_photography_outlined : Icons.camera_alt_outlined,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            message ??
                (supported
                    ? 'Bật camera để quét liên tục các mã vạch.'
                    : 'Camera chỉ hỗ trợ trên web, Android và iOS.'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: supported ? onStart : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Bật camera'),
          ),
        ],
      ),
    ),
  );
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography_outlined, size: 40),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Thử mở lại')),
        ],
      ),
    ),
  );
}
