const String kilnVersion = '0.1.1';
const String kilnCoreVersion = '0.1.1';

/// The release build overrides this with the exact commit it was compiled from.
const String defaultCoreGitRef = String.fromEnvironment(
  'KILN_CORE_GIT_REF',
  defaultValue: 'fbb6c968cfb11417b6a75c5129e4dff7b265cb5d',
);

/// The public repository a project resolves `kiln_core` from.
///
/// `kiln_core` is not published on pub.dev, so a project needs a source: a
/// local checkout (`--core-path`), an explicit URL (`--core-git`), or this
/// default. Baking it in keeps `kiln create` working from the compiled CLI on a
/// machine that has neither the workspace nor a pub.dev release.
const String defaultCoreGitUrl = 'https://github.com/MTegarPamungkas/kiln.git';
