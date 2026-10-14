import 'dart:async';

/// One "something changed" signal from several live Firestore listeners.
/// The first snapshot of each listener is the current state, not a change,
/// so it is skipped. Errors are dropped: callers reload and handle failures
/// there.
Stream<void> mergeChanges(List<Stream<Object?>> sources) {
  late final StreamController<void> controller;
  final subscriptions = <StreamSubscription<Object?>>[];
  controller = StreamController<void>(
    onListen: () {
      for (final source in sources) {
        subscriptions.add(
          source.skip(1).listen((_) => controller.add(null), onError: (_) {}),
        );
      }
    },
    onCancel: () async {
      for (final s in subscriptions) {
        await s.cancel();
      }
    },
  );
  return controller.stream;
}
