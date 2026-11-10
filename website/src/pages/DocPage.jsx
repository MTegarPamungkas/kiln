import { useLocation } from 'react-router-dom';
import { ExternalLink } from 'lucide-react';
import generated from '../content/generated.json';
import Markdown from '../components/Markdown';
import Breadcrumbs from '../components/Breadcrumbs';
import PageNav from '../components/PageNav';
import { flattenDocs, neighbors } from '../lib/nav';
import { stripLeadingTitle } from '../lib/text';
import { usePageTitle } from '../lib/use-page-title';
import NotFoundPage from './NotFoundPage';

const ordered = flattenDocs(generated.docs);

export default function DocPage() {
  const location = useLocation();
  const pathname = location.pathname.replace(/\/+$/, '') || '/docs';
  const doc = generated.docs.find((item) => item.route === pathname);
  usePageTitle(doc ? doc.title : 'Documentation not found');

  if (!doc) return <NotFoundPage />;

  const index = ordered.findIndex((item) => item.route === doc.route);
  const { previous, next } = neighbors(ordered, index);

  return (
    <article className="doc-page">
      <Breadcrumbs
        items={[
          { label: 'Docs', route: '/docs' },
          { label: doc.section },
          { label: doc.title },
        ]}
      />

      <header className="page-header">
        <span className="eyebrow">{doc.section}</span>
        <h1>{doc.title}</h1>
        {doc.description ? <p className="page-description">{doc.description}</p> : null}
        <div className="doc-actions">
          <a
            className="text-link"
            href={`https://github.com/MTegarPamungkas/kiln/blob/main/${doc.source}`}
            target="_blank"
            rel="noreferrer"
          >
            Edit on GitHub <ExternalLink size={13} />
          </a>
          <span className="muted">Source: {doc.source}</span>
        </div>
      </header>

      <Markdown markdown={stripLeadingTitle(doc.markdown)} />
      <PageNav previous={previous} next={next} />
    </article>
  );
}
