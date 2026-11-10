import { useEffect } from 'react';
import { Link, useParams } from 'react-router-dom';
import {
  ArrowUpRight,
  Box,
  Check,
  ExternalLink,
  FileText,
  Layers3,
  Puzzle,
  Settings2,
  Terminal,
} from 'lucide-react';
import generated from '../content/generated.json';
import ExtensionIcon from '../components/ExtensionIcon';
import Markdown from '../components/Markdown';
import Breadcrumbs from '../components/Breadcrumbs';
import CopyButton from '../components/CopyButton';
import PageNav from '../components/PageNav';
import { Badge, CapabilityPills, PlatformPills, TierBadge } from '../components/Badge';
import { CATEGORY_META, categoryLabel } from '../lib/categories';
import { neighbors } from '../lib/nav';
import { usePageMeta } from '../lib/page-meta';
import { stripLeadingTitle } from '../lib/text';
import { usePageTitle } from '../lib/use-page-title';
import NotFoundPage from './NotFoundPage';

function formatValue(value) {
  if (value == null || value === '') return '—';
  if (Array.isArray(value)) return value.join(', ');
  if (typeof value === 'object') return JSON.stringify(value);
  return String(value);
}

export default function ExtensionPage() {
  const { id } = useParams();
  const extension = generated.extensions.find((item) => item.id === id);
  const { setHeadings } = usePageMeta();
  usePageTitle(extension ? extension.name : 'Extension not found');
  useEffect(() => {
    if (!extension?.readme) setHeadings([]);
  }, [extension, setHeadings]);
  if (!extension) return <NotFoundPage />;

  const index = generated.extensions.findIndex((item) => item.id === extension.id);
  const { previous, next } = neighbors(generated.extensions, index);
  const meta = CATEGORY_META[extension.category];

  return (
    <article className="extension-page">
      <Breadcrumbs
        items={[
          { label: 'Extensions', route: '/extensions' },
          { label: categoryLabel(extension.category), route: `/extensions?category=${extension.category}` },
          { label: extension.name },
        ]}
      />

      <header className="extension-hero">
        <div className="extension-hero-main">
          <div className="extension-title-row">
            <ExtensionIcon category={extension.category} size={30} />
            <div>
              <div className="extension-kicker">
                <span>{meta?.label ?? categoryLabel(extension.category)}</span>
                <TierBadge tier={extension.tier} />
                <Badge tone="neutral">v{extension.version}</Badge>
                {extension.exclusive ? <Badge tone="amber">exclusive</Badge> : null}
              </div>
              <h1>{extension.name}</h1>
            </div>
          </div>
          <p className="extension-lead">{extension.description}</p>
          <div className="extension-facts">
            <div>
              <span>Capabilities</span>
              <CapabilityPills items={extension.provides} />
            </div>
            <div>
              <span>Platforms</span>
              <PlatformPills platforms={extension.platforms} />
            </div>
          </div>
        </div>
        <div className="install-card">
          <div className="install-card-head">
            <span><Terminal size={15} /> Install</span>
            <CopyButton text={extension.installCommand} />
          </div>
          <pre><code>{extension.installCommand}</code></pre>
          <a className="install-source" href={extension.sourceUrl} target="_blank" rel="noreferrer">
            View source <ExternalLink size={13} />
          </a>
        </div>
      </header>

      <nav className="jump-nav" aria-label="On this page">
        <a href="#overview"><FileText size={14} /> Overview</a>
        <a href="#configuration"><Settings2 size={14} /> Configuration</a>
        <a href="#integration"><Layers3 size={14} /> Integration</a>
        <a href="#usage"><Puzzle size={14} /> Gate usage</a>
        {extension.docs.length ? <a href="#docs"><Box size={14} /> Docs</a> : null}
      </nav>

      <section id="overview" className="doc-section">
        <h2>Overview</h2>
        {extension.readme ? (
          <Markdown markdown={stripLeadingTitle(extension.readme)} />
        ) : (
          <p className="muted">This extension has no README yet.</p>
        )}
      </section>

      <section id="configuration" className="doc-section">
        <h2>Configuration</h2>
        <p>
          Prompt answers are stored in <code>kiln.yaml</code> and passed to the
          renderer. Required prompts must be supplied with <code>--answer</code> in
          non-interactive runs.
        </p>
        {extension.prompts.length ? (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Prompt</th>
                  <th>Type</th>
                  <th>Required</th>
                  <th>Default</th>
                  <th>Description</th>
                </tr>
              </thead>
              <tbody>
                {extension.prompts.map((prompt) => (
                  <tr key={prompt.name}>
                    <td><code>{prompt.name}</code></td>
                    <td><Badge tone="neutral">{prompt.type}</Badge></td>
                    <td>{prompt.required ? <Check size={15} className="ok-icon" /> : '—'}</td>
                    <td><code>{formatValue(prompt.defaultValue)}</code></td>
                    <td>{prompt.description || prompt.label}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : (
          <p className="muted">This extension has no prompts; installing it needs no answers.</p>
        )}
      </section>

      <section id="integration" className="doc-section">
        <h2>Integration</h2>
        <div className="integration-grid">
          <div className="info-card">
            <h3>Capabilities</h3>
            <dl className="facts-list">
              <div>
                <dt>Provides</dt>
                <dd><CapabilityPills items={extension.provides} /></dd>
              </div>
              <div>
                <dt>Requires</dt>
                <dd><CapabilityPills items={extension.requires} empty="No hard requirements" /></dd>
              </div>
              <div>
                <dt>Optional</dt>
                <dd><CapabilityPills items={extension.optionalRequires} empty="None" /></dd>
              </div>
            </dl>
          </div>

          <div className="info-card">
            <h3>Dependencies</h3>
            {Object.keys(extension.dependencies).length ? (
              <ul className="dependency-list">
                {Object.entries(extension.dependencies).map(([name, version]) => (
                  <li key={name}>
                    <code>{name}</code>
                    <span>{formatValue(version)}</span>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="muted">No additional packages.</p>
            )}
            {Object.keys(extension.devDependencies).length ? (
              <>
                <h4>Dev dependencies</h4>
                <ul className="dependency-list">
                  {Object.entries(extension.devDependencies).map(([name, version]) => (
                    <li key={name}>
                      <code>{name}</code>
                      <span>{formatValue(version)}</span>
                    </li>
                  ))}
                </ul>
              </>
            ) : null}
          </div>

          <div className="info-card">
            <h3>Compatibility</h3>
            <ul className="dependency-list">
              <li><code>kiln</code><span>{formatValue(extension.compatibility.kiln)}</span></li>
              <li><code>dart</code><span>{formatValue(extension.compatibility.dart)}</span></li>
              {extension.compatibility.flutter ? (
                <li><code>flutter</code><span>{formatValue(extension.compatibility.flutter)}</span></li>
              ) : null}
            </ul>
          </div>

          <div className="info-card">
            <h3>Native setup</h3>
            <NativeSetup extension={extension} />
          </div>
        </div>

        {extension.slots.length || extension.contributes.length ? (
          <div className="info-card wide">
            <h3>Slots and contributions</h3>
            {extension.slots.map((slot) => (
              <div key={slot.name} className="slot-row">
                <Badge tone="violet">{slot.name}</Badge>
                <span>{slot.item}</span>
                <span className="muted">{slot.description}</span>
              </div>
            ))}
            {extension.contributes.map((contribution, index) => (
              <div key={`${contribution.slot}-${index}`} className="slot-row">
                <Badge tone="teal">{contribution.slot}</Badge>
                <span>{contribution.item}</span>
                <span className="muted">
                  priority {contribution.priority ?? 0}
                  {contribution.when?.length ? ` · when ${contribution.when.join(', ')}` : ''}
                </span>
              </div>
            ))}
          </div>
        ) : null}

        {extension.manualSteps.length ? (
          <div className="info-card wide">
            <h3>Manual steps after install</h3>
            <ol className="manual-steps">
              {extension.manualSteps.map((step) => (
                <li key={step.id}>
                  <strong>{step.id}</strong>
                  <p>{step.description}</p>
                </li>
              ))}
            </ol>
          </div>
        ) : null}
      </section>

      <section id="usage" className="doc-section">
        <h2>Gate usage</h2>
        <p>
          Read the capability through <code>Gate</code> so feature code gets an
          <code>Ok</code>/<code>Err</code> value instead of a thrown provider
          exception. The app owns the UI.
        </p>
        <Markdown
          markdown={`\`\`\`dart\n${extension.gateExample}\n\`\`\``}
          collectHeadings={false}
        />
        {extension.docs.length ? (
          <p>
            The extension README and topic docs below contain provider-specific
            examples for the full API.
          </p>
        ) : null}
      </section>

      {extension.docs.length ? (
        <section id="docs" className="doc-section">
          <h2>Documentation</h2>
          <div className="doc-card-grid">
            {extension.docs.map((doc) => (
              <Link key={doc.slug} to={doc.route} className="doc-link-card">
                <FileText size={16} />
                <span>{doc.title}</span>
                <ArrowUpRight size={14} />
              </Link>
            ))}
          </div>
        </section>
      ) : null}

      <PageNav previous={previous} next={next} />
    </article>
  );
}

function NativeSetup({ extension }) {
  const permissions = extension.android?.permissions ?? [];
  const entitlements = Object.entries(extension.macos?.entitlements ?? {});
  const ios = extension.ios ?? {};

  if (!permissions.length && !entitlements.length && !Object.keys(ios).length) {
    return <p className="muted">No native file changes.</p>;
  }

  return (
    <div className="native-setup">
      {permissions.length ? (
        <div>
          <h4>Android permissions</h4>
          <ul className="mono-list">
            {permissions.map((permission) => <li key={permission}><code>{permission}</code></li>)}
          </ul>
        </div>
      ) : null}
      {entitlements.length ? (
        <div>
          <h4>macOS entitlements</h4>
          <ul className="mono-list">
            {entitlements.map(([key, value]) => (
              <li key={key}><code>{key}</code> <span>{String(value)}</span></li>
            ))}
          </ul>
        </div>
      ) : null}
      {Object.keys(ios).length ? (
        <div>
          <h4>iOS setup</h4>
          <pre><code>{JSON.stringify(ios, null, 2)}</code></pre>
        </div>
      ) : null}
    </div>
  );
}
