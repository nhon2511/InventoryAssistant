import 'package:flutter/material.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/ai_result.dart';

class AiResultCard extends StatelessWidget {
  const AiResultCard({required this.result, required this.onChanged, super.key});
  final AiResult result;
  final ValueChanged<AiResult> onChanged;

  @override
  Widget build(BuildContext context) {
    if (result.type == AiResultType.text) return Text(result.text);
    if (result.type == AiResultType.stockInfo) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.inventory_2_outlined),
        if (result.productName != null) Text(result.productName!),
        Text(result.text),
      ]);
    }
    final cancelled = result.draftState == AiDraftState.cancelled;
    final reviewed = result.draftState == AiDraftState.reviewed;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(result.type == AiResultType.draftInbound ? 'BẢN NHÁP NHẬP KHO' : 'BẢN NHÁP XUẤT KHO',
          style: Theme.of(context).textTheme.titleSmall),
      Text('Sản phẩm: ${result.productName ?? 'Chưa xác định'}'),
      Text('Số lượng: ${result.quantity?.toString() ?? 'Chưa xác định'}'),
      if (result.lotCode != null) Text('Lô: ${result.lotCode}'),
      if (result.locationCode != null) Text('Vị trí: ${result.locationCode}'),
      Text(cancelled ? 'Đã hủy bản nháp' : reviewed
          ? 'Đã kiểm tra · chưa tạo phiếu' : 'Vui lòng kiểm tra trước khi tạo phiếu.'),
      if (!cancelled) Wrap(spacing: 8, children: [
        TextButton(onPressed: () => _edit(context), child: const Text('Chỉnh sửa')),
        if (!reviewed) TextButton(
          onPressed: () => onChanged(result.copyWith(draftState: AiDraftState.cancelled)),
          child: const Text('Hủy')),
        if (!reviewed) FilledButton(
          onPressed: result.productName == null || result.quantity == null || result.quantity! <= 0
              ? null : () => onChanged(result.copyWith(draftState: AiDraftState.reviewed)),
          child: const Text('Kiểm tra xong')),
      ]),
    ]);
  }

  Future<void> _edit(BuildContext context) async {
    final product = TextEditingController(text: result.productName);
    final quantity = TextEditingController(text: result.quantity?.toString() ?? '');
    final lot = TextEditingController(text: result.lotCode);
    final location = TextEditingController(text: result.locationCode);
    final formKey = GlobalKey<FormState>();
    final edited = await showDialog<AiResult>(context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chỉnh bản nháp'),
        content: SizedBox(width: 360, child: Form(key: formKey,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: product,
              decoration: const InputDecoration(labelText: 'Sản phẩm'),
              validator: (value) => value == null || value.trim().isEmpty ? 'Nhập sản phẩm' : null),
            TextFormField(controller: quantity, keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số lượng'),
              validator: (value) => (int.tryParse(value ?? '') ?? 0) <= 0
                  ? 'Số lượng phải lớn hơn 0' : null),
            TextFormField(controller: lot, decoration: const InputDecoration(labelText: 'Mã lô (nếu có)')),
            TextFormField(controller: location, decoration: const InputDecoration(labelText: 'Vị trí (nếu có)')),
          ])))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Đóng')),
          FilledButton(onPressed: () {
            if (!formKey.currentState!.validate()) return;
            Navigator.pop(dialogContext, result.copyWith(
              productName: product.text.trim(), quantity: int.parse(quantity.text),
              lotCode: lot.text.trim(), locationCode: location.text.trim(),
              draftState: AiDraftState.pending));
          }, child: const Text('Lưu bản nháp')),
        ],
      ));
    product.dispose();
    quantity.dispose();
    lot.dispose();
    location.dispose();
    if (edited != null) onChanged(edited);
  }
}
