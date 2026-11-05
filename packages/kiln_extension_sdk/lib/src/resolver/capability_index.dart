import '../manifest/extension_manifest.dart';

/// Indexes available extensions by id and by provided capability.
final class CapabilityIndex {
  CapabilityIndex(Iterable<AvailableExtension> extensions) {
    for (final extension in extensions) {
      _byId.putIfAbsent(extension.id, () => extension);
      for (final capability in extension.manifest.provides) {
        _byCapability
            .putIfAbsent(capability, () => <AvailableExtension>[])
            .add(extension);
      }
    }
  }

  final Map<String, AvailableExtension> _byId = <String, AvailableExtension>{};
  final Map<String, List<AvailableExtension>> _byCapability =
      <String, List<AvailableExtension>>{};

  Iterable<AvailableExtension> get extensions => _byId.values;

  Set<String> get allCapabilities => _byCapability.keys.toSet();

  AvailableExtension? byId(String id) => _byId[id];

  List<AvailableExtension> providersOf(String capability) =>
      List<AvailableExtension>.unmodifiable(
        _byCapability[capability] ?? const <AvailableExtension>[],
      );

  AvailableExtension? singleProviderOf(String capability) {
    final providers = providersOf(capability);
    return providers.length == 1 ? providers.single : null;
  }

  Set<String> capabilitiesOf(String extensionId) {
    final extension = _byId[extensionId];
    return extension == null
        ? const <String>{}
        : extension.manifest.provides.toSet();
  }
}
