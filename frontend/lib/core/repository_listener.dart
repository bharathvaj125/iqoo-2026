import 'dart:async';

import 'package:flutter/widgets.dart';

/// Rebuilds a screen whenever the repositories it depends on change.
///
/// The module home screens hold their panels in an IndexedStack of const widgets, so a
/// panel stays mounted and is never rebuilt just because another tab did something. Work
/// finished in one panel — completing a session, raising a trend flag — therefore has to
/// push, or the roster next door goes on showing what was true ten minutes ago.
mixin RepositoryListener<T extends StatefulWidget> on State<T> {
  final List<StreamSubscription<void>> _subscriptions = [];

  /// Call from initState with every repository stream this screen reads through.
  void listenTo(List<Stream<void>> streams) {
    for (final stream in streams) {
      _subscriptions.add(stream.listen((_) {
        if (mounted) setState(() {});
      }));
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
