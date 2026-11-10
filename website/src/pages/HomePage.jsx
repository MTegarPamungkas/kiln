import { Link } from 'react-router-dom';
import {
  ArrowRight,
  Boxes,
  CheckCircle2,
  CircuitBoard,
  GitBranch,
  Lock,
  PackageCheck,
  ShieldCheck,
  Sparkles,
  Terminal,
  Wand2,
} from 'lucide-react';
import generated from '../content/generated.json';
import ExtensionCard from '../components/ExtensionCard';
import CopyButton from '../components/CopyButton';
import { useClearHeadings } from '../lib/page-meta';
import { usePageTitle } from '../lib/use-page-title';

const FEATURED_IDS = ['dio', 'supabase', 'bloc', 'l10n', 'secure_storage', 'notifications'];

const QUICKSTART = `kiln create my_app \\
  --with dio,rest_auth,secure_storage \\
  --answer dio.base_url=https://api.example.com \\
  --answer rest_auth.base_url=https://api.example.com`;

export default function HomePage() {
  usePageTitle('Composable Flutter applications');
  useClearHeadings();
  const featured = FEATURED_IDS.map((id) =>
    generated.extensions.find((extension) => extension.id === id),
  ).filter(Boolean);

  return (
    <div className="home">
      <section className="hero">
        <div className="hero-copy">
          <span className="eyebrow">
            <Sparkles size={14} /> Flutter framework · v{generated.version ?? '0.1.1'}
          </span>
          <h1>
            Build Flutter apps that
            <span className="gradient-text"> age like fired clay.</span>
          </h1>
          <p className="hero-lead">
            Kiln composes applications from typed contracts, one Result gate, and
            transactional extensions. Your app owns the UI. Extensions own the
            wiring. Nothing imports anything it should not.
          </p>
          <div className="hero-actions">
            <Link className="button primary" to="/docs/getting-started">
              Get started <ArrowRight size={16} />
            </Link>
            <Link className="button" to="/extensions">
              Browse {generated.stats.extensions} extensions
            </Link>
          </div>
          <div className="hero-stats">
            <div>
              <strong>{generated.stats.extensions}</strong>
              <span>extensions</span>
            </div>
            <div>
              <strong>{generated.stats.categories}</strong>
              <span>categories</span>
            </div>
            <div>
              <strong>{generated.stats.prompts}</strong>
              <span>typed prompts</span>
            </div>
            <div>
              <strong>1.8k+</strong>
              <span>tests passing</span>
            </div>
          </div>
        </div>

        <div className="hero-visual" aria-hidden="true">
          <div className="orb orb-one" />
          <div className="orb orb-two" />
          <div className="hero-card">
            <div className="hero-card-top">
              <span className="dot red" />
              <span className="dot amber" />
              <span className="dot green" />
              <span className="hero-card-title">main.dart</span>
            </div>
            <pre>
              <code>
{`final registry = await KilnBootstrap.run(
  modules: kilnModules(),
);

final gate = Gate(registry);
final notes = await gate.remoteQuery('notes');

return notes.fold(
  ok: (rows) => NotesView(rows),
  err: (failure) => ErrorView(failure),
);`}
              </code>
            </pre>
            <div className="hero-card-result">
              <CheckCircle2 size={15} />
              <span>Ok(List&lt;Map&lt;String, Object?&gt;&gt;)</span>
            </div>
          </div>
        </div>
      </section>

      <section className="section quickstart">
        <div className="section-heading">
          <span className="eyebrow">Quick start</span>
          <h2>From zero to a wired app in one command.</h2>
          <p>
            The CLI resolves capabilities, renders extension bricks, patches native
            files, verifies the result, and rolls back as one transaction.
          </p>
        </div>
        <div className="command-card">
          <div className="command-card-head">
            <span>
              <Terminal size={15} /> Terminal
            </span>
            <CopyButton text={QUICKSTART} />
          </div>
          <pre><code>{QUICKSTART}</code></pre>
        </div>
      </section>

      <section className="section">
        <div className="section-heading">
          <span className="eyebrow">Why Kiln</span>
          <h2>A small surface with strong invariants.</h2>
        </div>
        <div className="feature-grid">
          <Feature
            icon={CircuitBoard}
            title="One gate, one result"
            text="Every capability is reachable through Gate. Calls return Ok or Err with a stable FailureCode, so feature code never catches provider exceptions."
            link="/docs/concepts/contract-behavior"
          />
          <Feature
            icon={ShieldCheck}
            title="Vendor-neutral contracts"
            text="Features read AuthRepository, RemoteDatabase, FileStorage, and HttpClient. Swap Appwrite, Supabase, Firebase, Neon, or REST without touching UI."
            link="/docs/concepts/contracts-and-capabilities"
          />
          <Feature
            icon={Lock}
            title="Transactional installs"
            text="Rendering, native patches, dependency changes, the lockfile, and codegen share one journaled transaction with backups and rollback."
            link="/docs/concepts/transactions-and-rollback"
          />
          <Feature
            icon={PackageCheck}
            title="Ownership-aware"
            text="Kiln never edits user code. Remove and upgrade only touch files whose hashes still match, and dependency provenance is recorded."
            link="/docs/concepts/lockfile-and-ownership"
          />
          <Feature
            icon={Wand2}
            title="33 composable extensions"
            text="Auth, data, storage, networking, navigation, device APIs, state, observability, and tooling — each with prompts, docs, and contract tests."
            link="/extensions"
          />
          <Feature
            icon={GitBranch}
            title="Capabilities, not ids"
            text="Extensions require capabilities such as http_client or remote_database. The resolver picks a provider and catches conflicts and cycles."
            link="/docs/adr/0002-capabilities-not-ids"
          />
        </div>
      </section>

      <section className="section gate-showcase">
        <div className="gate-copy">
          <span className="eyebrow">The Gate</span>
          <h2>Success or failure, with information. Never UI.</h2>
          <p>
            The SDK sends back a typed outcome and the app decides what to render.
            The same shape covers permissions, auth, storage, HTTP, files, analytics,
            and device services.
          </p>
          <ul className="check-list">
            <li><CheckCircle2 size={15} /> Stable FailureCode values</li>
            <li><CheckCircle2 size={15} /> Details carry status, operation, and server context</li>
            <li><CheckCircle2 size={15} /> Missing extensions return Err, not StateError</li>
            <li><CheckCircle2 size={15} /> Unsupported devices return typed support failures</li>
          </ul>
          <Link className="text-link" to="/docs/concepts/contract-behavior">
            Read the contract behavior spec <ArrowRight size={15} />
          </Link>
        </div>
        <div className="gate-code">
          <div className="command-card-head">
            <span>permission request</span>
            <CopyButton
              text={`final result = await gate.requestPermission(PermissionKind.camera);\nresult.fold(\n  ok: (status) => print('Granted: $status'),\n  err: (failure) => print('${'${failure.code}'}: ${'${failure.details}'}'),\n);`}
            />
          </div>
          <pre><code>{`final result = await gate.requestPermission(
  PermissionKind.camera,
);

result.fold(
  ok: (status) => print('Granted: $status'),
  err: (failure) => print(
    '${'${failure.code}'}: ${'${failure.details}'}',
  ),
);`}</code></pre>
        </div>
      </section>

      <section className="section">
        <div className="section-heading split">
          <div>
            <span className="eyebrow">Extension catalog</span>
            <h2>Pick a capability. The app stays yours.</h2>
          </div>
          <Link className="button" to="/extensions">
            All extensions <ArrowRight size={15} />
          </Link>
        </div>
        <div className="extension-grid home-grid">
          {featured.map((extension) => (
            <ExtensionCard key={extension.id} extension={extension} featured />
          ))}
        </div>
      </section>

      <section className="section">
        <div className="section-heading">
          <span className="eyebrow">Backend swap</span>
          <h2>Same feature code. Different backend.</h2>
          <p>
            The backend_swap example keeps <code>lib/features/notes</code> and
            <code>lib/main.dart</code> byte-identical while Appwrite and Supabase
            provide the same contracts underneath.
          </p>
        </div>
        <div className="backend-row">
          {['Appwrite', 'Supabase', 'Firebase', 'Neon', 'REST API', 'Your own'].map((name) => (
            <div key={name} className="backend-chip">
              <Boxes size={16} />
              {name}
            </div>
          ))}
        </div>
        <div className="backend-arrow">
          <span />
          <strong>RemoteDatabase · AuthRepository · FileStorage</strong>
          <span />
        </div>
      </section>

      <section className="section cta">
        <div>
          <span className="eyebrow">Start building</span>
          <h2>Create the app. Add only what it needs.</h2>
          <p>
            The generated project analyzes clean and ships with tests. Add an
            extension, swap a provider, or publish your own.
          </p>
        </div>
        <div className="cta-actions">
          <Link className="button primary" to="/docs/getting-started">
            Getting started <ArrowRight size={16} />
          </Link>
          <Link className="button" to="/docs/extensions/writing-an-extension">
            Write an extension
          </Link>
        </div>
      </section>
    </div>
  );
}

function Feature({ icon: Icon, title, text, link }) {
  return (
    <Link to={link} className="feature-card">
      <span className="feature-icon"><Icon size={20} /></span>
      <h3>{title}</h3>
      <p>{text}</p>
      <span className="feature-link">Learn more <ArrowRight size={13} /></span>
    </Link>
  );
}
