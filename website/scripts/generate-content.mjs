import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import YAML from 'yaml';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, '..', '..');
const websiteDir = path.resolve(scriptDir, '..');
const outputFile = path.join(websiteDir, 'src', 'content', 'generated.json');
const githubRoot = 'https://github.com/MTegarPamungkas/kiln/blob/main';

const read = (relative) => fs.readFileSync(path.join(root, relative), 'utf8');
const exists = (relative) => fs.existsSync(path.join(root, relative));

function walk(relativeDir) {
  const absolute = path.join(root, relativeDir);
  if (!fs.existsSync(absolute)) return [];
  const entries = fs.readdirSync(absolute, { withFileTypes: true });
  return entries.flatMap((entry) => {
    const relative = path.posix.join(relativeDir, entry.name);
    if (entry.isDirectory()) return walk(relative);
    return entry.isFile() && entry.name.endsWith('.md') ? [relative] : [];
  });
}

function titleOf(markdown, fallback) {
  const match = markdown.match(/^#\s+(.+)$/m);
  return match ? match[1].trim() : fallback;
}

function stripMarkdown(markdown) {
  return markdown
    .replace(/```[\s\S]*?```/g, ' ')
    .replace(/`([^`]+)`/g, '$1')
    .replace(/!\[[^\]]*\]\([^)]*\)/g, ' ')
    .replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
    .replace(/^\s{0,3}#{1,6}\s+/gm, '')
    .replace(/^\s{0,3}>\s?/gm, '')
    .replace(/[*_~]/g, '')
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function descriptionOf(markdown) {
  const paragraphs = markdown
    .replace(/```[\s\S]*?```/g, '')
    .split(/\n\s*\n/)
    .map((paragraph) => paragraph.trim())
    .filter(
      (paragraph) =>
        paragraph &&
        !paragraph.startsWith('#') &&
        !paragraph.startsWith('|') &&
        !paragraph.startsWith('---'),
    );
  const text = stripMarkdown(paragraphs[0] ?? '');
  return text.length > 180 ? `${text.slice(0, 177)}…` : text;
}

const sectionFor = (relative) => {
  if (relative === 'docs/README.md') return 'Overview';
  if (relative === 'docs/getting-started.md') return 'Overview';
  if (relative === 'docs/architecture.md') return 'Overview';
  if (relative === 'docs/roadmap.md') return 'Overview';
  if (relative.startsWith('docs/concepts/')) return 'Concepts';
  if (relative.startsWith('docs/guides/')) return 'Guides';
  if (relative.startsWith('docs/extensions/')) return 'Build extensions';
  if (relative.startsWith('docs/cli/')) return 'Reference';
  if (relative.startsWith('docs/adr/')) return 'Architecture decisions';
  return 'Reference';
};

const docRoute = (relative) => {
  if (relative === 'docs/README.md') return '/docs';
  return `/docs/${relative.replace(/^docs\//, '').replace(/\.md$/, '')}`;
};

const routeMap = new Map();
const docs = walk('docs').map((relative) => {
  const markdown = read(relative);
  const route = docRoute(relative);
  routeMap.set(relative, route);
  return {
    source: relative,
    route,
    title: titleOf(markdown, path.basename(relative, '.md')),
    section: sectionFor(relative),
    description: descriptionOf(markdown),
    markdown,
    kind: 'doc',
  };
});
routeMap.set('README.md', '/');

const extraDocs = [
  {
    source: 'examples/full_stack/README.md',
    route: '/docs/examples/full_stack',
    section: 'Examples',
  },
  {
    source: 'examples/backend_swap/README.md',
    route: '/docs/examples/backend-swap',
    section: 'Examples',
  },
  {
    source: 'examples/custom_extension/README.md',
    route: '/docs/examples/custom-extension',
    section: 'Examples',
  },
  {
    source: 'examples/minimal/README.md',
    route: '/docs/examples/minimal',
    section: 'Examples',
  },
  {
    source: 'CONTRIBUTING.md',
    route: '/docs/contributing',
    section: 'Project',
  },
  {
    source: 'SECURITY.md',
    route: '/docs/security',
    section: 'Project',
  },
  {
    source: 'CODE_OF_CONDUCT.md',
    route: '/docs/code-of-conduct',
    section: 'Project',
  },
].filter((entry) => exists(entry.source));

for (const entry of extraDocs) {
  const markdown = read(entry.source);
  routeMap.set(entry.source, entry.route);
  docs.push({
    source: entry.source,
    route: entry.route,
    title: titleOf(markdown, path.basename(entry.source, '.md')),
    section: entry.section,
    description: descriptionOf(markdown),
    markdown,
    kind: 'doc',
  });
}

const extensionDirs = fs
  .readdirSync(path.join(root, 'extensions'), { withFileTypes: true })
  .filter(
    (entry) =>
      entry.isDirectory() &&
      exists(`extensions/${entry.name}/extension.yaml`),
  )
  .map((entry) => entry.name);

const asArray = (value) => (Array.isArray(value) ? value : value == null ? [] : [value]);
const asObject = (value) =>
  value && typeof value === 'object' && !Array.isArray(value) ? value : {};

const placeholderFor = (prompt) => {
  switch (prompt.type) {
    case 'url':
      return 'https://api.example.com';
    case 'secret':
      return '<secret>';
    case 'int':
      return `${prompt.default ?? prompt.min ?? 1}`;
    case 'bool':
      return `${prompt.default ?? true}`;
    case 'enum':
      return `${prompt.default ?? prompt.options?.[0] ?? '<value>'}`;
    case 'multi':
      return asArray(prompt.default ?? prompt.options?.[0]).join(',') || '<values>';
    default:
      return prompt.default != null ? `${prompt.default}` : '<value>';
  }
};

const installCommandFor = (extension) => {
  const required = asArray(extension.prompts).filter(
    (prompt) => prompt.required && (prompt.default == null || prompt.default === ''),
  );
  const args = required.map(
    (prompt) => `--answer ${prompt.name}=${placeholderFor(prompt)}`,
  );
  return ['kiln add ' + extension.id, ...args].join(' ');
};

const gateExamples = {
  http_client: `final response = await gate.httpGet(Uri.parse('/health'));
response.fold(
  ok: (value) => print(value.statusCode),
  err: (failure) => print(failure.code),
);`,
  auth: `final session = await gate.signIn(
  email: 'user@example.com',
  password: '••••••••',
);`,
  remote_database: `final notes = await gate.remoteQuery('notes');
final one = await gate.remoteRead('notes', id);`,
  file_storage: `final file = await gate.uploadFile(
  FileUpload(path: 'avatars/user.png', bytes: pngBytes),
);
final link = await gate.files.url('avatars/user.png');`,
  analytics: `await gate.captureEvent(
  'checkout_started',
  properties: {'cart': 3},
);`,
  secure_storage: `final token = await gate.readSecure('access_token');
await gate.writeSecure('access_token', token);`,
  storage: `await gate.writeValue('theme', 'dark');
final theme = await gate.readValue('theme');`,
  connectivity: `final online = await gate.network.status;
final changes = gate.network.changes;`,
  permission: `final status = await gate.requestPermission(PermissionKind.camera);`,
  media_picker: `final image = await gate.pickImage(source: MediaSource.gallery);`,
  notifications: `await gate.showNotification(
  const NotificationMessage(id: 1, title: 'Hi', body: 'There'),
);`,
  location: `final position = await gate.currentLocation();
final enabled = await gate.locationServiceEnabled();`,
  calendar: `final added = await gate.addCalendarEvent(event);`,
  share: `await gate.shareContent(const ShareContent(text: 'Hello from Kiln'));`,
  social_auth: `final credential = await gate.socialSignIn(SocialProvider.google);`,
  crash_reporter: `await gate.reportError(error, stackTrace: stackTrace);`,
  local_db: `await gate.localPut('settings', 'theme', {'mode': 'dark'});`,
  http_cache: `await gate.invalidateCache('/users');
await gate.clearCache();`,
};

const gateExampleFor = (extension) => {
  for (const capability of asArray(extension.provides)) {
    if (gateExamples[capability]) return gateExamples[capability];
  }
  if (asArray(extension.provides).includes('theme')) {
    return `// Extension-specific gate lives next to the extension code.
final theme = await gate.setThemeMode(ThemeMode.dark);`;
  }
  if (asArray(extension.provides).includes('l10n')) {
    return `// Extension-specific gate lives next to the extension code.
await gate.setLocale(const Locale('id'));`;
  }
  return `if (gate.has<YourContract>()) {
  final service = gate.use<YourContract>();
  // Call the contract, then fold the Result.
}`;
};

const normalizePrompt = (prompt) => ({
  name: prompt.name,
  type: prompt.type ?? 'string',
  label: prompt.label ?? prompt.name,
  description: prompt.description ?? '',
  defaultValue: prompt.default ?? null,
  required: prompt.required === true,
  secret: prompt.secret === true,
  options: asArray(prompt.options),
  min: prompt.min ?? null,
  max: prompt.max ?? null,
});

const extensions = extensionDirs.map((id) => {
  const manifest = YAML.parse(read(`extensions/${id}/extension.yaml`)) ?? {};
  const readmePath = `extensions/${id}/README.md`;
  const readme = exists(readmePath) ? read(readmePath) : '';
  const docsDir = `extensions/${id}/docs`;
  const extensionDocs = walk(docsDir).map((relative) => {
    const markdown = read(relative);
    const slug = path.basename(relative, '.md');
    const route = `/extensions/${id}/docs/${slug}`;
    routeMap.set(relative, route);
    return {
      source: relative,
      slug,
      route,
      title: titleOf(markdown, slug),
      markdown,
    };
  });
  routeMap.set(readmePath, `/extensions/${id}`);

  const extension = {
    id,
    name: manifest.name ?? id,
    version: manifest.version ?? '0.0.0',
    description: manifest.description ?? '',
    category: manifest.category ?? 'tooling',
    tier: manifest.tier ?? 'community',
    exclusive: manifest.exclusive === true,
    provides: asArray(manifest.provides),
    requires: asArray(manifest.requires),
    optionalRequires: asArray(manifest.optional_requires),
    dependencies: asObject(manifest.dependencies),
    devDependencies: asObject(manifest.dev_dependencies),
    platforms: asArray(manifest.platforms),
    prompts: asArray(manifest.prompts).map(normalizePrompt),
    slots: asArray(manifest.slots),
    contributes: asArray(manifest.contributes),
    manualSteps: asArray(manifest.manual_steps),
    compatibility: asObject(manifest.compatibility),
    android: asObject(manifest.android),
    macos: asObject(manifest.macos),
    ios: asObject(manifest.ios),
    flutter: asObject(manifest.flutter),
    readme,
    docs: extensionDocs,
    sourceUrl: `https://github.com/MTegarPamungkas/kiln/tree/main/extensions/${id}`,
    route: `/extensions/${id}`,
    installCommand: '',
    gateExample: '',
  };
  extension.installCommand = installCommandFor(extension);
  extension.gateExample = gateExampleFor(extension);
  return extension;
});

extensions.sort((left, right) => left.name.localeCompare(right.name));

function rewriteLinks(markdown, sourcePath) {
  const sourceDir = path.posix.dirname(sourcePath);
  let inFence = false;
  return markdown
    .split('\n')
    .map((line) => {
      if (/^\s*(```|~~~)/.test(line)) {
        inFence = !inFence;
        return line;
      }
      if (inFence) return line;
      return line.replace(
        /(!?\[[^\]]*\]\()([^)\s]+)((?:\s+"[^"]*")?\))/g,
        (full, prefix, target, suffix) => {
          if (
            /^(https?:|mailto:|tel:|#|\/\/|\/)/i.test(target) ||
            target.startsWith('/')
          ) {
            return full;
          }
          const [pathPart, anchorPart] = target.split('#');
          if (!pathPart) return full;
          const resolved = path.posix.normalize(path.posix.join(sourceDir, pathPart));
          const route = routeMap.get(resolved);
          if (route) {
            return `${prefix}${route}${anchorPart ? `#${anchorPart}` : ''}${suffix}`;
          }
          if (resolved === 'README.md') {
            return `${prefix}/${anchorPart ? `#${anchorPart}` : ''}${suffix}`;
          }
          const url = `${githubRoot}/${resolved}`;
          return `${prefix}${url}${anchorPart ? `#${anchorPart}` : ''}${suffix}`;
        },
      );
    })
    .join('\n');
}

for (const doc of docs) {
  doc.markdown = rewriteLinks(doc.markdown, doc.source);
}
for (const extension of extensions) {
  extension.readme = rewriteLinks(extension.readme, `extensions/${extension.id}/README.md`);
  for (const doc of extension.docs) {
    doc.markdown = rewriteLinks(doc.markdown, doc.source);
  }
}

const search = [];
for (const doc of docs) {
  search.push({
    title: doc.title,
    description: doc.description,
    route: doc.route,
    type: 'Guide',
    text: stripMarkdown(doc.markdown).slice(0, 2400),
  });
}
search.push({
  title: 'Extensions',
  description: 'Browse all bundled capabilities: auth, storage, network, UI, device, and tooling.',
  route: '/extensions',
  type: 'Catalog',
  text: 'extension catalog auth storage network device ui tooling',
});
for (const extension of extensions) {
  search.push({
    title: extension.name,
    description: extension.description,
    route: extension.route,
    type: 'Extension',
    text: [
      extension.id,
      extension.category,
      extension.provides.join(' '),
      extension.requires.join(' '),
      extension.prompts.map((prompt) => prompt.name).join(' '),
      stripMarkdown(extension.readme),
    ]
      .join(' ')
      .slice(0, 2400),
  });
  for (const doc of extension.docs) {
    search.push({
      title: `${extension.name} · ${doc.title}`,
      description: descriptionOf(doc.markdown),
      route: doc.route,
      type: 'Extension docs',
      text: stripMarkdown(doc.markdown).slice(0, 2000),
    });
  }
}

const categories = [...new Set(extensions.map((extension) => extension.category))].sort();
const versionSource = read('packages/kiln_cli/lib/src/version.dart');
const version = versionSource.match(/kilnVersion\s*=\s*'([^']+)'/)?.[1] ?? '0.1.0';
const packages = fs
  .readdirSync(path.join(root, 'packages'), { withFileTypes: true })
  .filter(
    (entry) =>
      entry.isDirectory() && exists(`packages/${entry.name}/pubspec.yaml`),
  ).length;

const payload = {
  generatedAt: new Date().toISOString(),
  version,
  stats: {
    extensions: extensions.length,
    docs: docs.length,
    categories: categories.length,
    prompts: extensions.reduce((total, extension) => total + extension.prompts.length, 0),
    packages,
  },
  categories,
  docs,
  extensions,
  search,
};

fs.mkdirSync(path.dirname(outputFile), { recursive: true });
fs.writeFileSync(outputFile, `${JSON.stringify(payload, null, 2)}\n`);
console.log(
  `Generated ${payload.docs.length} docs, ${payload.extensions.length} extensions, ${payload.search.length} search entries → ${path.relative(root, outputFile)}`,
);
