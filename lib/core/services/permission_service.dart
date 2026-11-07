import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Trạng thái quyền tùy chỉnh rõ ràng theo yêu cầu Smart WMS.
enum AppPermissionStatus { granted, denied, permanentlyDenied }

/// Dịch vụ quản lý quyền Camera và Microphone cho ứng dụng Smart WMS.
class PermissionService {
  const PermissionService();

  /// Chuyển đổi từ permission_handler status sang AppPermissionStatus
  AppPermissionStatus _mapStatus(PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return AppPermissionStatus.granted;
    } else if (status.isPermanentlyDenied || status.isRestricted) {
      return AppPermissionStatus.permanentlyDenied;
    } else {
      return AppPermissionStatus.denied;
    }
  }

  /// Kiểm tra quyền Camera
  Future<AppPermissionStatus> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return _mapStatus(status);
  }

  /// Yêu cầu quyền Camera
  Future<AppPermissionStatus> requestCameraPermission({
    BuildContext? context,
    VoidCallback? onPermanentlyDenied,
  }) async {
    final status = await Permission.camera.request();
    final appStatus = _mapStatus(status);

    if (appStatus == AppPermissionStatus.permanentlyDenied &&
        context != null &&
        context.mounted) {
      _showSettingsDialog(
        context,
        title: 'Quyền Camera bị chặn',
        message: 'Ứng dụng cần quyền Camera để quét mã vạch kho hàng. Vui lòng vào Cài đặt để cấp quyền.',
        onPermanentlyDenied: onPermanentlyDenied,
      );
    }
    return appStatus;
  }

  /// Kiểm tra quyền Microphone
  Future<AppPermissionStatus> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return _mapStatus(status);
  }

  /// Yêu cầu quyền Microphone
  Future<AppPermissionStatus> requestMicrophonePermission({
    BuildContext? context,
    VoidCallback? onPermanentlyDenied,
  }) async {
    final status = await Permission.microphone.request();
    final appStatus = _mapStatus(status);

    if (appStatus == AppPermissionStatus.permanentlyDenied &&
        context != null &&
        context.mounted) {
      _showSettingsDialog(
        context,
        title: 'Quyền Microphone bị chặn',
        message: 'Ứng dụng cần quyền Microphone để nhập lệnh bằng giọng nói. Vui lòng vào Cài đặt để cấp quyền.',
        onPermanentlyDenied: onPermanentlyDenied,
      );
    }
    return appStatus;
  }

  /// Kiểm tra đồng thời cả Camera và Microphone
  Future<Map<String, AppPermissionStatus>> checkAllPermissions() async {
    final cameraStatus = await checkCameraPermission();
    final micStatus = await checkMicrophonePermission();
    return {'camera': cameraStatus, 'microphone': micStatus};
  }

  /// Yêu cầu đồng thời cả Camera và Microphone
  Future<Map<String, AppPermissionStatus>> requestAllPermissions({
    BuildContext? context,
    VoidCallback? onPermanentlyDenied,
  }) async {
    final statuses = await [Permission.camera, Permission.microphone].request();

    final cameraStatus = _mapStatus(
      statuses[Permission.camera] ?? PermissionStatus.denied,
    );
    final micStatus = _mapStatus(
      statuses[Permission.microphone] ?? PermissionStatus.denied,
    );

    if ((cameraStatus == AppPermissionStatus.permanentlyDenied ||
            micStatus == AppPermissionStatus.permanentlyDenied) &&
        context != null &&
        context.mounted) {
      _showSettingsDialog(
        context,
        title: 'Quyền bị chặn vĩnh viễn',
        message: 'Smart WMS cần quyền Camera và Microphone để hoạt động đầy đủ tính năng quét mã vạch và giọng nói. Vui lòng mở Cài đặt để cấp quyền.',
        onPermanentlyDenied: onPermanentlyDenied,
      );
    }

    return {'camera': cameraStatus, 'microphone': micStatus};
  }

  /// Hiển thị hộp thoại hướng dẫn mở App Settings khi quyền bị chặn vĩnh viễn
  void _showSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onPermanentlyDenied,
  }) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await openAppSettings();
                if (onPermanentlyDenied != null) {
                  onPermanentlyDenied();
                }
              },
              child: const Text('Mở Cài đặt'),
            ),
          ],
        );
      },
    );
  }
}
