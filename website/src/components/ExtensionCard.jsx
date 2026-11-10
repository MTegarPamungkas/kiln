import { Link } from 'react-router-dom';
import { ArrowUpRight } from 'lucide-react';
import ExtensionIcon from './ExtensionIcon';
import { Badge, TierBadge } from './Badge';
import { CATEGORY_META, categoryLabel } from '../lib/categories';

export default function ExtensionCard({ extension, featured = false }) {
  const meta = CATEGORY_META[extension.category];
  return (
    <Link
      to={extension.route}
      className={`extension-card ${featured ? 'featured' : ''}`}
    >
      <div className="extension-card-top">
        <ExtensionIcon category={extension.category} size={featured ? 26 : 22} />
        <span className="extension-card-category">{meta?.label ?? categoryLabel(extension.category)}</span>
        <ArrowUpRight className="extension-card-arrow" size={16} />
      </div>
      <h3>{extension.name}</h3>
      <p>{extension.description}</p>
      <div className="extension-card-meta">
        <TierBadge tier={extension.tier} />
        <Badge tone="neutral">v{extension.version}</Badge>
        {extension.provides.slice(0, 2).map((capability) => (
          <Badge key={capability} tone="teal">
            {capability}
          </Badge>
        ))}
      </div>
    </Link>
  );
}
