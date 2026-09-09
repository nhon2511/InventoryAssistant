import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/core/errors/failures.dart';

/// Shorthand for [Future] that returns [Either] a [Failure] or [T].
typedef FutureEither<T> = Future<Either<Failure, T>>;

/// Shorthand for [Future] that returns [Either] a [Failure] or [void].
typedef FutureVoid = FutureEither<void>;
