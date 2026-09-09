import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_info.g.dart';

/// Abstraction to check network connectivity.
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

/// Implementation using [InternetConnection] from
/// `internet_connection_checker_plus`.
class NetworkInfoImpl implements NetworkInfo {
  const NetworkInfoImpl(this._connectionChecker);

  final InternetConnection _connectionChecker;

  @override
  Future<bool> get isConnected => _connectionChecker.hasInternetAccess;
}

@riverpod
NetworkInfo networkInfo(NetworkInfoRef ref) {
  return NetworkInfoImpl(InternetConnection());
}
