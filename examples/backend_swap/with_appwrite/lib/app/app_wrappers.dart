import 'package:flutter/widgets.dart';
import 'package:kiln_core/kiln_core.dart';

/// Wraps the whole application, for example a flavor banner or an app lock.
typedef AppWrapper = Widget Function(BuildContext context, Widget child);

/// Reads the wrappers contributed to [SlotNames.appWrappers].
List<AppWrapper> appWrappers(Registry registry) {
  final slots = registry.readOrNull<SlotRegistry>();
  if (slots == null) {
    return const <AppWrapper>[];
  }
  return slots.open<AppWrapper>(SlotNames.appWrappers).items;
}
