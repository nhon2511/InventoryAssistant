import 'package:smart_wms/core/utils/typedefs.dart';

/// Base class for all use cases in the application.
///
/// [T] is the return type of the use case.
/// [Params] is the input parameters type.
///
/// Example:
/// ```dart
/// class GetProductByBarcode extends UseCase<Product, String> {
///   @override
///   FutureEither<Product> call(String barcode) async { ... }
/// }
/// ```
// ignore: one_member_abstracts
abstract class UseCase<T, Params> {
  const UseCase();

  FutureEither<T> call(Params params);
}

/// Use when the use case does not require any parameters.
///
/// Example:
/// ```dart
/// class SignOut extends UseCase<void, NoParams> {
///   @override
///   FutureEither<void> call(NoParams params) async { ... }
/// }
/// ```
class NoParams {
  const NoParams();
}
