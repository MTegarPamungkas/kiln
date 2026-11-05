import 'package:kiln_core/kiln_core.dart';

/// Opens the interceptor slot so contributors can append middleware.
OrderedSlot<HttpMiddleware> httpInterceptorSlot(Registry registry) {
  return registry.read<SlotRegistry>().open<HttpMiddleware>(
    SlotNames.httpInterceptors,
  );
}
