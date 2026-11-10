import { Link } from 'react-router-dom';
import { Compass } from 'lucide-react';
import { useClearHeadings } from '../lib/page-meta';
import { usePageTitle } from '../lib/use-page-title';

export default function NotFoundPage() {
  usePageTitle('Page not found');
  useClearHeadings();
  return (
    <div className="not-found">
      <span className="eyebrow"><Compass size={14} /> 404</span>
      <h1>That page is not in the kiln.</h1>
      <p>The link may be old, or the document moved.</p>
      <div className="not-found-actions">
        <Link className="button primary" to="/docs">Documentation home</Link>
        <Link className="button" to="/extensions">Extensions</Link>
      </div>
    </div>
  );
}
