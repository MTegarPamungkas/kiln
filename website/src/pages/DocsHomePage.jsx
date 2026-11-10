import { Link } from 'react-router-dom';
import {
  BookMarked,
  Boxes,
  Compass,
  Landmark,
  Layers3,
  Rocket,
  Settings2,
  ShieldCheck,
  Terminal,
  Wrench,
} from 'lucide-react';
import generated from '../content/generated.json';
import { buildDocsNav } from '../lib/nav';
import { useClearHeadings } from '../lib/page-meta';
import { usePageTitle } from '../lib/use-page-title';

const SECTION_ICONS = {
  Overview: Rocket,
  Concepts: Layers3,
  Guides: Compass,
  Examples: Boxes,
  'Build extensions': Wrench,
  Reference: Terminal,
  Project: ShieldCheck,
  'Architecture decisions': Landmark,
};

const SECTION_COPY = {
  Overview: 'Create a project, understand the runtime, and see what is shipping.',
  Concepts: 'Contracts, capabilities, behavior, security, slots, and transactions.',
  Guides: 'Step-by-step recipes for backends, offline, flavors, and migrations.',
  Examples: 'Generated apps you can run, read, and copy from.',
  'Build extensions': 'Manifest, brick, tests, trust, publishing, and the catalog.',
  Reference: 'CLI commands, flags, and the target repository layout.',
  Project: 'Contributing, security policy, and community expectations.',
  'Architecture decisions': 'The decisions that shaped Kiln, with their tradeoffs.',
};

export default function DocsHomePage() {
  usePageTitle('Documentation');
  useClearHeadings();
  const sections = buildDocsNav(generated.docs);

  return (
    <div className="docs-home">
      <header className="page-header docs-hero">
        <span className="eyebrow"><BookMarked size={14} /> Documentation</span>
        <h1>Everything you need to build with Kiln.</h1>
        <p>
          Start with a generated app, learn the runtime contracts, then install only
          the capabilities you need. The docs are generated from the same repository
          as the code.
        </p>
        <div className="docs-hero-actions">
          <Link className="button primary" to="/docs/getting-started">Getting started</Link>
          <Link className="button" to="/extensions">Extension catalog</Link>
        </div>
      </header>

      <div className="docs-section-grid">
        {sections.map((section) => {
          const Icon = SECTION_ICONS[section.label] ?? Settings2;
          return (
            <section key={section.label} className="docs-section-card">
              <div className="docs-section-head">
                <span className="feature-icon"><Icon size={18} /></span>
                <div>
                  <h2>{section.label}</h2>
                  <p>{SECTION_COPY[section.label]}</p>
                </div>
              </div>
              <ul>
                {section.items.map((item) => (
                  <li key={item.route}>
                    <Link to={item.route}>{item.title}</Link>
                  </li>
                ))}
              </ul>
            </section>
          );
        })}
      </div>

      <section className="docs-note">
        <strong>Generated from the repo.</strong>
        <p>
          This site reads {generated.stats.docs} markdown documents and {generated.stats.extensions}{' '}
          extension manifests at build time. When the code changes, run{' '}
          <code>npm run content</code> before building.
        </p>
      </section>
    </div>
  );
}
