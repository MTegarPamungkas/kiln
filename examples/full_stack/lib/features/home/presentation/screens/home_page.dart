import 'package:full_stack/app/registry_scope.dart';
import 'package:full_stack/core/l10n/core_copy.dart';
import 'package:full_stack/extensions/l10n/gate_l10n.dart';
import 'package:full_stack/extensions/theme/gate_theme.dart';
import 'package:kiln_core/kiln_core.dart';
import 'package:material_ui/material_ui.dart';

/// Starting page owned by the application.
///
/// Demonstrates Kiln's Gate verbs (theme, locale), GoRouter navigation into
/// the Bloc-backed Notes feature, and live runtime status from SupportRegistry.
class HomePage extends StatelessWidget {
  const HomePage({this.onOpenNotes, super.key});

  final VoidCallback? onOpenNotes;

  @override
  Widget build(BuildContext context) {
    final registry = RegistryScope.of(context);
    final gate = registry.readOrNull<Gate>();
    final copy = registry.read<CoreCopy>();
    final support = registry.readOrNull<SupportRegistry>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final currentLocale = Localizations.localeOf(context).languageCode;
    final entries =
        (support?.all.entries.toList() ??
              <MapEntry<String, SupportInfo>>[])
          ..sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      appBar: AppBar(
        title: Text(copy.appTitle(context)),
        actions: <Widget>[
          IconButton(
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: gate == null
                ? null
                : () {
                    final next = isDark ? ThemeMode.light : ThemeMode.dark;
                    gate.setThemeMode(next).ignore();
                  },
          ),
          TextButton(
            onPressed: gate == null
                ? null
                : () {
                    final next = currentLocale == 'id'
                        ? const Locale('en')
                        : const Locale('id');
                    gate.setLocale(next).ignore();
                  },
            child: Text(currentLocale.toUpperCase()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colors.primaryContainer,
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Kiln Full-Stack Demo',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entries.length} extensions active · '
                          '${isDark ? 'Dark' : 'Light'} · '
                          '${currentLocale.toUpperCase()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.checklist_rounded),
              title: const Text('Notes (Bloc CRUD)'),
              subtitle: const Text(
                'Add, toggle, and remove notes through NotesBloc & GoRouter',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: onOpenNotes,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Runtime Support (${entries.length})',
            style: theme.textTheme.titleSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          for (final entry in entries)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                leading: Icon(
                  entry.value.isSupported
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  color: entry.value.isSupported
                      ? colors.primary
                      : colors.error,
                ),
                title: Text(entry.key),
                subtitle: Text(entry.value.state.name),
              ),
            ),
        ],
      ),
    );
  }
}
