import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_wms/features/outbound/domain/entities/pick_list_item.dart';
import 'package:smart_wms/features/outbound/domain/usecases/verify_scanned_item_usecase.dart';
import 'package:smart_wms/features/outbound/presentation/controllers/pick_verify_controller.dart';
import 'package:vibration/vibration.dart';

class PickVerifyScreen extends ConsumerStatefulWidget {
  const PickVerifyScreen({required this.orderId, super.key});
  final String orderId;

  @override
  ConsumerState<PickVerifyScreen> createState() => _PickVerifyScreenState();
}

