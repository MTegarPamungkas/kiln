import { Link, useParams } from 'react-router-dom';
import { ArrowLeft, ExternalLink, FileText } from 'lucide-react';
import generated from '../content/generated.json';
import Markdown from '../components/Markdown';
import Breadcrumbs from '../components/Breadcrumbs';
import PageNav from '../components/PageNav';
import { neighbors } from '../lib/nav';
import { stripLeadingTitle } from '../lib/text';
import { usePageTitle } from '../lib/use-page-title';
import NotFoundPage from './NotFoundPage';

export default function ExtensionDocPage() {
  const { id, doc: slug } = useParams();
  const extension = generated.extensions.find((item) => item.id === id);
  const doc = extension?.docs.find((item) => item.slug === slug);
  usePageTitle(doc ? `${doc.title} · ${extension.name}` : 'Documentation not found');

  if (!extension || !doc) return <NotFoundPage />;

  const items = [
    { title: 'Overview', route: extension.route },
    ...extension.docs.map((item) => ({ title: item.title, route: item.route })),
  ];
  const index = items.findIndex((item) => item.route === doc.route);
  const { previous, next } = neighbors(items, index);

  return (
    <article className="doc-page">
      <Breadcrumbs
        items={[
          { label: 'Extensions', route: '/extensions' },
          { label: extension.name, route: extension.route },
          { label: doc.title },
        ]}
      />

      <header className="page-header">
        <div className="doc-kicker">
          <FileText size={15} />
          <span>{extension.name} documentation</span>
        </div>
        <h1>{doc.title}</h1>
        <div className="doc-actions">
          <a
            className="text-link"
            href={`https://github.com/MTegarPamungkas/kiln/blob/main/${doc.source}`}
            target="_blank"
            rel="noreferrer"
          >
            Edit on GitHub <ExternalLink size={13} />
          </a>
          <Link className="text-link" to={extension.route}>
            <ArrowLeft size={13} /> Back to {extension.name}
          </Link>
        </div>
      </header>

      <div className="extension-doc-nav">
        {items.map((item) => (
          <Link
            key={item.route}
            to={item.route}
            className={item.route === doc.route ? 'active' : ''}
          >
            {item.title}
          </Link>
        ))}
      </div>

      <Markdown markdown={stripLeadingTitle(doc.markdown)} />
      <PageNav previous={previous} next={next} />
    </article>
  );
}
