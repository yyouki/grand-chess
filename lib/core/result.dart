sealed class Result<T, E> {
  const Result();

  const factory Result.ok(T value) = Ok<T, E>;
  const factory Result.err(E error) = Err<T, E>;

  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  T? get valueOrNull => switch (this) {
    Ok<T, E>(:final value) => value,
    Err<T, E>() => null,
  };

  E? get errorOrNull => switch (this) {
    Ok<T, E>() => null,
    Err<T, E>(:final error) => error,
  };

  R when<R>({
    required R Function(T value) ok,
    required R Function(E error) err,
  }) {
    return switch (this) {
      Ok<T, E>(:final value) => ok(value),
      Err<T, E>(:final error) => err(error),
    };
  }
}

final class Ok<T, E> extends Result<T, E> {
  final T value;
  const Ok(this.value);
}

final class Err<T, E> extends Result<T, E> {
  final E error;
  const Err(this.error);
}
