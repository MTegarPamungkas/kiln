import 'package:flutter/widgets.dart';
import 'package:kiln_core/kiln_core.dart';

/// Cancels in-flight requests when the owning widget is disposed.
mixin HttpCancelTokenOwner<T extends StatefulWidget> on State<T> {
  final HttpCancelToken httpCancelToken = HttpCancelToken();

  @override
  void dispose() {
    httpCancelToken.cancel();
    super.dispose();
  }
}
