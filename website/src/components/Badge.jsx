export function Badge({ children, tone = 'neutral', className = '' }) {
  return <span className={`badge tone-${tone} ${className}`.trim()}>{children}</span>;
}

export function TierBadge({ tier }) {
  const tone = tier === 'official' ? 'blue' : tier === 'verified' ? 'violet' : 'neutral';
  return <Badge tone={tone}>{tier}</Badge>;
}

const PLATFORM_LABELS = {
  android: 'Android',
  ios: 'iOS',
  macos: 'macOS',
  web: 'Web',
  windows: 'Windows',
  linux: 'Linux',
};

export function PlatformPills({ platforms }) {
  if (!platforms?.length) {
    return <Badge tone="neutral">All platforms</Badge>;
  }
  return (
    <div className="pill-row">
      {platforms.map((platform) => (
        <Badge key={platform} tone="neutral">
          {PLATFORM_LABELS[platform] ?? platform}
        </Badge>
      ))}
    </div>
  );
}

export function CapabilityPills({ items, tone = 'teal', empty = 'None' }) {
  if (!items?.length) {
    return <span className="muted">{empty}</span>;
  }
  return (
    <div className="pill-row">
      {items.map((item) => (
        <Badge key={item} tone={tone}>
          {item}
        </Badge>
      ))}
    </div>
  );
}
