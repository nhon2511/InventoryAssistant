import 'package:flutter/material.dart';
import 'package:smart_wms/app/theme/app_tokens.dart';
import 'package:smart_wms/core/enums/order_status.dart';
import 'package:smart_wms/core/widgets/app_controls.dart';
import 'package:smart_wms/core/widgets/error_widget.dart';
import 'package:smart_wms/core/widgets/empty_state_widget.dart';
import 'package:smart_wms/core/widgets/loading_widget.dart';
import 'package:smart_wms/core/widgets/status_chip.dart';

/// Internal preview for the components shared across the feature teams.
class WidgetGalleryScreen extends StatelessWidget {
  const WidgetGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Thư viện giao diện')),
        body: ListView(
          padding: const EdgeInsets.all(AppTokens.lg),
          children: [
            Text('Nút và biểu mẫu', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTokens.md),
            Wrap(spacing: AppTokens.sm, runSpacing: AppTokens.sm, children: [
              AppButton(label: 'Xác nhận', onPressed: () {}),
              AppButton(label: 'Viền', outlined: true, onPressed: () {}),
              const AppButton(label: 'Đang lưu', busy: true, onPressed: null),
            ]),
            const SizedBox(height: AppTokens.sm),
            const AppTextField(label: 'Mã sản phẩm'),
            AppSelect<String>(label: 'Trạng thái', options: const {'draft': 'Nháp'}, onChanged: (_) {}),
            AppSearchField(onChanged: (_) {}),
            const AppCard(child: Text('Card dùng chung')),
            SizedBox(height: 100, child: AppDataList<String>(
              items: const ['Sản phẩm A', 'Sản phẩm B'],
              itemBuilder: (context, item) => ListTile(title: Text(item)))),
            const SizedBox(height: AppTokens.xl),
            Text('Trạng thái', style: Theme.of(context).textTheme.titleLarge),
            const Wrap(
              spacing: AppTokens.sm,
              children: [
                StatusChip.inStock(),
                StatusChip.lowStock(),
                StatusChip.outOfStock(),
              ],
            ),
            StatusChip.order(OrderStatus.confirmed),
            const QuantityBadge(quantity: 8),
            ExpiryWarningChip(expiryDate: DateTime.now().add(const Duration(days: 12))),
            Wrap(spacing: AppTokens.sm, children: [
              AppButton(label: 'Snackbar', onPressed: () => AppFeedback.show(context, 'Đã lưu')),
              AppButton(label: 'Dialog', outlined: true,
                onPressed: () => AppFeedback.confirm(context, title: 'Xác nhận?', message: 'Tiếp tục?')),
              AppButton(label: 'Bottom sheet', outlined: true,
                onPressed: () => AppFeedback.sheet<void>(context, const Text('Bảng thao tác'))),
            ]),
            const SizedBox(height: AppTokens.xl),
            Text('Trạng thái màn hình', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTokens.md),
            const SizedBox(height: 100, child: AppLoadingWidget()),
            const SizedBox(
              height: 160,
              child: EmptyStateWidget(message: 'Chưa có dữ liệu'),
            ),
            const SizedBox(height: 160, child: AppErrorWidget(message: 'Không tải được dữ liệu.')),
          ],
        ),
      );
}
