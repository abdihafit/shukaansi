import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/application/auth_controller.dart';
import 'package:shukaansi/services/auth_service.dart';

// Test-only provider; never part of the application's production composition.
class ControlledAuthService implements AuthService {
  final pending = Completer<void>();
  int calls = 0;
  bool? registered;
  @override
  bool get isConfigured => true;

  Future<void> invoke(bool register, String email, String password) {
    calls++;
    registered = register;
    expect(email, 'test@example.com');
    expect(password, ' passphrase unchanged ');
    return pending.future;
  }

  @override
  Future<void> register({required String email, required String password}) =>
      invoke(true, email, password);
  @override
  Future<void> signIn({required String email, required String password}) =>
      invoke(false, email, password);
}

Future<void> submit(AuthController controller, {bool registering = true}) =>
    controller.submit(
      registering: registering,
      email: ' test@example.com ',
      password: ' passphrase unchanged ',
    );

void main() {
  test('unconfigured service fails closed', () async {
    final controller = AuthController(const UnconfiguredAuthService());
    addTearDown(controller.dispose);
    await submit(controller);
    expect(controller.failure, AuthFailure.unavailable);
    expect(controller.completed, isFalse);
    expect(controller.busy, isFalse);
  });

  for (final registering in [true, false]) {
    test(
      'routes operation and suppresses duplicate requests: $registering',
      () async {
        final service = ControlledAuthService();
        final controller = AuthController(service);
        addTearDown(controller.dispose);
        final request = submit(controller, registering: registering);
        expect(controller.busy, isTrue);
        await submit(controller);
        expect(service.calls, 1);
        expect(service.registered, registering);
        service.pending.complete();
        await request;
        expect(controller.completed, isTrue);
        expect(controller.busy, isFalse);
      },
    );
  }

  for (final failure in AuthFailure.values) {
    test('maps safe failure $failure and clears it on reset', () async {
      final service = ControlledAuthService();
      final controller = AuthController(service);
      addTearDown(controller.dispose);
      final request = submit(controller);
      service.pending.completeError(AuthServiceException(failure));
      await request;
      expect(controller.failure, failure);
      expect(controller.completed, isFalse);
      controller.reset();
      expect(controller.failure, isNull);
    });
  }

  test('unexpected provider exceptions are sanitized', () async {
    final service = ControlledAuthService();
    final controller = AuthController(service);
    addTearDown(controller.dispose);
    final request = submit(controller);
    service.pending.completeError(
      StateError('provider details must remain private'),
    );
    await request;
    expect(controller.failure, AuthFailure.unknown);
  });

  test('late completion after disposal does not notify listeners', () async {
    final service = ControlledAuthService();
    final controller = AuthController(service);
    var notifications = 0;
    controller.addListener(() => notifications++);
    final request = submit(controller);
    controller.dispose();
    service.pending.complete();
    await request;
    expect(notifications, 1);
  });
}
