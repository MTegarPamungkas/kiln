export const CATEGORY_META = {
  analytics: { label: 'Analytics', group: 'observability', icon: 'Activity' },
  auth: { label: 'Authentication', group: 'auth', icon: 'KeyRound' },
  calendar: { label: 'Calendar', group: 'device', icon: 'CalendarDays' },
  codegen: { label: 'Code generation', group: 'tooling', icon: 'Code2' },
  config: { label: 'Configuration', group: 'observability', icon: 'Settings2' },
  connectivity: { label: 'Connectivity', group: 'network', icon: 'Wifi' },
  crash: { label: 'Crash reporting', group: 'observability', icon: 'Bug' },
  database: { label: 'Database', group: 'data', icon: 'Database' },
  deep_link: { label: 'Deep links', group: 'device', icon: 'Link2' },
  flavor: { label: 'Flavors', group: 'ui', icon: 'Tag' },
  l10n: { label: 'Localization', group: 'ui', icon: 'Languages' },
  location: { label: 'Location', group: 'device', icon: 'MapPin' },
  logging: { label: 'Logging', group: 'observability', icon: 'ScrollText' },
  media: { label: 'Media', group: 'device', icon: 'Image' },
  navigation: { label: 'Navigation', group: 'ui', icon: 'Compass' },
  network: { label: 'Networking', group: 'network', icon: 'Globe2' },
  notifications: { label: 'Notifications', group: 'device', icon: 'Bell' },
  platform: { label: 'Platform', group: 'device', icon: 'Layers' },
  security: { label: 'Security', group: 'auth', icon: 'Shield' },
  share: { label: 'Sharing', group: 'device', icon: 'Share2' },
  social: { label: 'Social', group: 'auth', icon: 'Users' },
  state: { label: 'State management', group: 'state', icon: 'Blocks' },
  storage: { label: 'Storage', group: 'data', icon: 'HardDrive' },
  theme: { label: 'Theming', group: 'ui', icon: 'Palette' },
  tooling: { label: 'Tooling', group: 'tooling', icon: 'Wrench' },
};

export const CATEGORY_GROUPS = [
  {
    key: 'auth',
    label: 'Auth & backends',
    categories: ['auth', 'social', 'security'],
  },
  {
    key: 'data',
    label: 'Data & storage',
    categories: ['storage', 'database'],
  },
  {
    key: 'network',
    label: 'Network',
    categories: ['network', 'connectivity'],
  },
  {
    key: 'ui',
    label: 'Navigation & UI',
    categories: ['navigation', 'theme', 'l10n', 'flavor'],
  },
  {
    key: 'device',
    label: 'Device',
    categories: ['media', 'notifications', 'location', 'calendar', 'share', 'platform', 'deep_link'],
  },
  { key: 'state', label: 'State', categories: ['state'] },
  {
    key: 'observability',
    label: 'Observability & config',
    categories: ['analytics', 'crash', 'logging', 'config'],
  },
  { key: 'tooling', label: 'Tooling', categories: ['tooling', 'codegen'] },
];

export const categoryLabel = (category) =>
  CATEGORY_META[category]?.label ?? category;

export const groupLabel = (key) =>
  CATEGORY_GROUPS.find((group) => group.key === key)?.label ?? key;
