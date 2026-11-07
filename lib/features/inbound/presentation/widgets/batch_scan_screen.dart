import 'package:flutter/material.dart';
import 'package:smart_wms/features/inbound/presentation/widgets/barcode_lookup_screen.dart';

/// Lookup only until a verified batch receiving backend contract is available.
class BatchScanScreen extends StatelessWidget {
  const BatchScanScreen({super.key});
  @override
  Widget build(BuildContext context) => const BarcodeLookupScreen();
}
