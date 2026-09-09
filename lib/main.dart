import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_wms/app/app.dart';
import 'package:smart_wms/bootstrap.dart';

void main() async {
  await bootstrap();

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}

