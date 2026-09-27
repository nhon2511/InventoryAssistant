import 'package:flutter/material.dart';
import 'package:smart_wms/app/theme/app_tokens.dart';
import 'package:smart_wms/core/widgets/confirm_dialog.dart';

class AppButton extends StatelessWidget {
  const AppButton({required this.label, required this.onPressed, super.key,
    this.icon, this.outlined = false, this.busy = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined, busy;
  @override
  Widget build(BuildContext context) {
    final child = busy ? const SizedBox(width: 20, height: 20,
      child: CircularProgressIndicator(strokeWidth: 2))
      : Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: AppTokens.sm)],
        Text(label),
      ]);
    return SizedBox(height: AppTokens.touchTarget, child: outlined
      ? OutlinedButton(onPressed: busy ? null : onPressed, child: child)
      : FilledButton(onPressed: busy ? null : onPressed, child: child));
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({required this.label, super.key, this.controller,
    this.hint, this.validator, this.keyboardType, this.onChanged});
  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => TextFormField(controller: controller,
    decoration: InputDecoration(labelText: label, hintText: hint),
    validator: validator, keyboardType: keyboardType, onChanged: onChanged);
}

class AppSelect<T> extends StatelessWidget {
  const AppSelect({required this.label, required this.options,
    required this.onChanged, super.key, this.value});
  final String label;
  final Map<T, String> options;
  final T? value;
  final ValueChanged<T?> onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: value, decoration: InputDecoration(labelText: label),
    items: options.entries.map((entry) => DropdownMenuItem<T>(
      value: entry.key, child: Text(entry.value))).toList(),
    onChanged: onChanged);
}

class AppSearchField extends StatelessWidget {
  const AppSearchField({required this.onChanged, super.key, this.hint = 'Tìm kiếm'});
  final ValueChanged<String> onChanged;
  final String hint;
  @override
  Widget build(BuildContext context) => TextField(
    decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: hint),
    onChanged: onChanged);
}

class AppCard extends StatelessWidget {
  const AppCard({required this.child, super.key, this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(child: InkWell(onTap: onTap,
    child: Padding(padding: const EdgeInsets.all(AppTokens.lg), child: child)));
}

class AppDataList<T> extends StatelessWidget {
  const AppDataList({required this.items, required this.itemBuilder, super.key});
  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  @override
  Widget build(BuildContext context) => ListView.builder(itemCount: items.length,
    itemBuilder: (context, index) => itemBuilder(context, items[index]));
}

abstract final class AppFeedback {
  static void show(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  static Future<bool> confirm(BuildContext context, {required String title,
    required String message}) => ConfirmDialog.show(context, title: title,
    content: message);
  static Future<T?> sheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(context: context, isScrollControlled: true,
      builder: (_) => SafeArea(child: child));
}
