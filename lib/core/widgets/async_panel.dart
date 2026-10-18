import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wms/core/widgets/error_widget.dart';
import 'package:smart_wms/core/widgets/loading_widget.dart';

class AsyncPanel<T> extends StatelessWidget {
  const AsyncPanel({
    required this.value,
    required this.builder,
    required this.onRetry,
    super.key,
  });
  final AsyncValue<T> value;
  final Widget Function(T) builder;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => value.when(
    loading: () => const AppLoadingWidget(message: 'Đang tải dữ liệu...'),
    error: (_, _) => AppErrorWidget(
      message: 'Không tải được dữ liệu. Kiểm tra kết nối hoặc quyền truy cập rồi thử lại.',
      onRetry: onRetry,
    ),
    data: builder,
  );
}
