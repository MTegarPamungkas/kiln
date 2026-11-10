const DOC_SECTIONS = [
  {
    label: 'Overview',
    sources: ['docs/getting-started.md', 'docs/architecture.md', 'docs/roadmap.md'],
  },
  {
    label: 'Concepts',
    sources: [
      'docs/concepts/contracts-and-capabilities.md',
      'docs/concepts/contract-behavior.md',
      'docs/concepts/compatibility.md',
      'docs/concepts/security-model.md',
      'docs/concepts/slots.md',
      'docs/concepts/native-patches.md',
      'docs/concepts/lockfile-and-ownership.md',
      'docs/concepts/transactions-and-rollback.md',
    ],
  },
  {
    label: 'Guides',
    sources: [
      'docs/guides/setup-flavors-and-env.md',
      'docs/guides/add-offline-support.md',
      'docs/guides/swap-backend.md',
      'docs/guides/migrate-bloc-to-riverpod.md',
      'docs/guides/android-kotlin-plugin-warning.md',
    ],
  },
  {
    label: 'Examples',
    sources: [
      'examples/full_stack/README.md',
      'examples/backend_swap/README.md',
      'examples/custom_extension/README.md',
      'examples/minimal/README.md',
    ],
  },
  {
    label: 'Build extensions',
    sources: [
      'docs/extensions/writing-an-extension.md',
      'docs/extension-manifest.md',
      'docs/extensions/testing-extensions.md',
      'docs/extensions/support-and-devices.md',
      'docs/extensions/trust-tiers.md',
      'docs/extensions/publishing.md',
      'docs/extensions/catalog.md',
    ],
  },
  {
    label: 'Reference',
    sources: ['docs/cli/reference.md', 'docs/folder-structure.md'],
  },
  {
    label: 'Project',
    sources: ['CONTRIBUTING.md', 'SECURITY.md', 'CODE_OF_CONDUCT.md'],
  },
  {
    label: 'Architecture decisions',
    sources: [
      'docs/adr/0001-never-edit-user-code.md',
      'docs/adr/0002-capabilities-not-ids.md',
      'docs/adr/0003-hooks-and-trust.md',
      'docs/adr/0004-transactions-and-journal.md',
      'docs/adr/0005-checksums-and-registry.md',
    ],
  },
];

export function buildDocsNav(docs) {
  const bySource = new Map(docs.map((doc) => [doc.source, doc]));
  return DOC_SECTIONS.map((section) => ({
    label: section.label,
    items: section.sources
      .map((source) => bySource.get(source))
      .filter(Boolean)
      .map((doc) => ({ title: doc.title, route: doc.route })),
  }));
}

export function flattenDocs(docs) {
  const bySource = new Map(docs.map((doc) => [doc.source, doc]));
  return DOC_SECTIONS.flatMap((section) =>
    section.sources.map((source) => bySource.get(source)).filter(Boolean),
  );
}

export function neighbors(items, index) {
  return {
    previous: index > 0 ? items[index - 1] : null,
    next: index >= 0 && index < items.length - 1 ? items[index + 1] : null,
  };
}
