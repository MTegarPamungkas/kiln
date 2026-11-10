import { Link } from 'react-router-dom';
import { ArrowLeft, ArrowRight } from 'lucide-react';

export default function PageNav({ previous, next }) {
  if (!previous && !next) return null;
  return (
    <nav className="page-nav" aria-label="Previous and next page">
      {previous ? (
        <Link to={previous.route} className="page-nav-link previous">
          <span className="page-nav-direction">
            <ArrowLeft size={14} /> Previous
          </span>
          <span>{previous.title}</span>
        </Link>
      ) : (
        <span />
      )}
      {next ? (
        <Link to={next.route} className="page-nav-link next">
          <span className="page-nav-direction">
            Next <ArrowRight size={14} />
          </span>
          <span>{next.title}</span>
        </Link>
      ) : null}
    </nav>
  );
}
