import { useEffect, useMemo, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import Fuse from 'fuse.js';
import { BookOpen, CornerDownLeft, FileText, Puzzle, Search, X } from 'lucide-react';

const TYPE_ICONS = {
  Extension: Puzzle,
  Guide: BookOpen,
  Catalog: Puzzle,
  'Extension docs': FileText,
};

const FEATURED = [
  '/docs/getting-started',
  '/docs/architecture',
  '/docs/concepts/contract-behavior',
  '/docs/cli/reference',
  '/extensions',
  '/extensions/supabase',
  '/extensions/bloc',
  '/extensions/l10n',
];

export default function SearchDialog({ open, onClose, entries }) {
  const navigate = useNavigate();
  const inputRef = useRef(null);
  const [query, setQuery] = useState('');
  const [active, setActive] = useState(0);

  const fuse = useMemo(
    () =>
      new Fuse(entries, {
        keys: [
          { name: 'title', weight: 0.55 },
          { name: 'description', weight: 0.25 },
          { name: 'text', weight: 0.2 },
        ],
        threshold: 0.34,
        ignoreLocation: true,
        minMatchCharLength: 2,
      }),
    [entries],
  );

  const results = useMemo(() => {
    if (!query.trim()) {
      const byRoute = new Map(entries.map((entry) => [entry.route, entry]));
      return FEATURED.map((route) => byRoute.get(route)).filter(Boolean);
    }
    return fuse.search(query).slice(0, 10).map((result) => result.item);
  }, [entries, fuse, query]);

  useEffect(() => {
    if (!open) return undefined;
    setQuery('');
    setActive(0);
    const timer = window.setTimeout(() => inputRef.current?.focus(), 20);
    const previous = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      window.clearTimeout(timer);
      document.body.style.overflow = previous;
    };
  }, [open]);

  useEffect(() => {
    setActive(0);
  }, [query]);

  if (!open) return null;

  function choose(entry) {
    if (!entry) return;
    onClose();
    navigate(entry.route);
  }

  function onKeyDown(event) {
    if (event.key === 'Escape') {
      event.preventDefault();
      onClose();
      return;
    }
    if (event.key === 'ArrowDown') {
      event.preventDefault();
      setActive((index) => Math.min(index + 1, results.length - 1));
      return;
    }
    if (event.key === 'ArrowUp') {
      event.preventDefault();
      setActive((index) => Math.max(index - 1, 0));
      return;
    }
    if (event.key === 'Enter') {
      event.preventDefault();
      choose(results[active]);
    }
  }

  return (
    <div className="search-overlay" role="presentation" onMouseDown={onClose}>
      <div
        className="search-panel"
        role="dialog"
        aria-modal="true"
        aria-label="Search documentation"
        onMouseDown={(event) => event.stopPropagation()}
      >
        <div className="search-input-row">
          <Search size={18} />
          <input
            ref={inputRef}
            type="text"
            value={query}
            placeholder="Search extensions, guides, CLI commands…"
            onChange={(event) => setQuery(event.target.value)}
            onKeyDown={onKeyDown}
            aria-label="Search documentation"
          />
          <button type="button" className="icon-button" onClick={onClose} aria-label="Close search">
            <X size={16} />
          </button>
        </div>

        <div className="search-results">
          <p className="search-label">{query.trim() ? 'Results' : 'Start here'}</p>
          {results.length === 0 ? (
            <p className="search-empty">No results. Try “auth”, “cache”, or “offline”.</p>
          ) : (
            <ul>
              {results.map((entry, index) => {
                const Icon = TYPE_ICONS[entry.type] ?? FileText;
                return (
                  <li key={`${entry.route}-${entry.title}`}>
                    <button
                      type="button"
                      className={index === active ? 'search-result active' : 'search-result'}
                      onMouseEnter={() => setActive(index)}
                      onClick={() => choose(entry)}
                    >
                      <span className="search-result-icon">
                        <Icon size={16} />
                      </span>
                      <span className="search-result-copy">
                        <span className="search-result-title">{entry.title}</span>
                        <span className="search-result-description">{entry.description}</span>
                      </span>
                      <span className="search-result-type">{entry.type}</span>
                      {index === active ? <CornerDownLeft size={14} /> : null}
                    </button>
                  </li>
                );
              })}
            </ul>
          )}
        </div>

        <div className="search-footer">
          <span>
            <kbd>↑</kbd>
            <kbd>↓</kbd> navigate
          </span>
          <span>
            <kbd>↵</kbd> open
          </span>
          <span>
            <kbd>esc</kbd> close
          </span>
        </div>
      </div>
    </div>
  );
}
