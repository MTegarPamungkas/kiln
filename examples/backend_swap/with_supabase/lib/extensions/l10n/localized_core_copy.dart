import 'package:flutter/widgets.dart';
import 'package:with_supabase/core/l10n/core_copy.dart';
import 'package:with_supabase/l10n/generated/app_localizations.dart';

/// [CoreCopy] backed by the generated ARB messages.
final class LocalizedCoreCopy implements CoreCopy {
  const LocalizedCoreCopy();

  AppLocalizations _strings(BuildContext context) =>
      AppLocalizations.of(context);

  @override
  String appTitle(BuildContext context) => _strings(context).appTitle;

  @override
  String readyTitle(BuildContext context) => _strings(context).readyTitle;

  @override
  String readyBody(BuildContext context) => _strings(context).readyBody;

  @override
  String starterHint(BuildContext context) => _strings(context).starterHint;

  @override
  String errorTitle(BuildContext context) => _strings(context).errorTitle;

  @override
  String errorBody(BuildContext context) => _strings(context).errorBody;

  @override
  String retry(BuildContext context) => _strings(context).actionRetry;
}
