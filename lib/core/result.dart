import 'package:flutter/foundation.dart';

sealed class Result<T> {
  const Result();

  factory Result.success(T value) = Success<T>;
  factory Result.failure(AppException error) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        Failure<T>() => null,
      };

  AppException? get errorOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(:final error) => error,
      };

  R fold<R>(R Function(T value) onSuccess, R Function(AppException error) onFailure) =>
      switch (this) {
        Success<T>(:final value) => onSuccess(value),
        Failure<T>(:final error) => onFailure(error),
      };

  T unwrap() => switch (this) {
        Success<T>(:final value) => value,
        Failure<T>(:final error) => throw error,
      };
}

class Success<T> implements Result<T> {
  final T value;
  const Success(this.value);

  @override
  bool get isSuccess => true;

  @override
  bool get isFailure => false;

  @override
  T? get valueOrNull => value;

  @override
  AppException? get errorOrNull => null;

  @override
  R fold<R>(R Function(T value) onSuccess, R Function(AppException error) onFailure) =>
      onSuccess(value);

  @override
  T unwrap() => value;

  @override
  String toString() => 'Success($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Success<T> && other.value == value);

  @override
  int get hashCode => value.hashCode;
}

class Failure<T> implements Result<T> {
  final AppException error;
  const Failure(this.error);

  @override
  bool get isSuccess => false;

  @override
  bool get isFailure => true;

  @override
  T? get valueOrNull => null;

  @override
  AppException? get errorOrNull => error;

  @override
  R fold<R>(R Function(T value) onSuccess, R Function(AppException error) onFailure) =>
      onFailure(error);

  @override
  T unwrap() => throw error;

  @override
  String toString() => 'Failure($error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Failure<T> && other.error == error);

  @override
  int get hashCode => error.hashCode;
}

class AppException {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.code,
    this.stackTrace,
  });

  @override
  String toString() =>
      'AppException($code: $message)${stackTrace != null ? '\n${stackTrace!}' : ''}';

  void log() {
    debugPrint('[SGI Error] $message${code != null ? ' ($code)' : ''}');
    if (stackTrace != null) {
      debugPrint(stackTrace!.toString().substring(0, 200));
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppException &&
          other.message == message &&
          other.code == code);

  @override
  int get hashCode => Object.hash(message, code);
}
