import { useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Filter, Search, X } from 'lucide-react';
import generated from '../content/generated.json';
import ExtensionCard from '../components/ExtensionCard';
import { Badge } from '../components/Badge';
import {
  CATEGORY_GROUPS,
  CATEGORY_META,
  categoryLabel,
  groupLabel,
} from '../lib/categories';
import { useClearHeadings } from '../lib/page-meta';
import { usePageTitle } from '../lib/use-page-title';

export default function CatalogPage() {
  usePageTitle('Extensions');
  useClearHeadings();
  const [params, setParams] = useSearchParams();
  const [query, setQuery] = useState('');
  const group = params.get('group');
  const category = params.get('category');
  const groupMeta = CATEGORY_GROUPS.find((item) => item.key === group);

  const extensions = useMemo(() => {
    const normalized = query.trim().toLowerCase();
    return generated.extensions.filter((extension) => {
      if (category && extension.category !== category) return false;
      if (groupMeta && !groupMeta.categories.includes(extension.category)) return false;
      if (!normalized) return true;
      const haystack = [
        extension.id,
        extension.name,
        extension.description,
        extension.category,
        extension.provides.join(' '),
        extension.requires.join(' '),
        extension.prompts.map((prompt) => prompt.name).join(' '),
      ]
        .join(' ')
        .toLowerCase();
      return haystack.includes(normalized);
    });
  }, [category, groupMeta, query]);

  function setFilter(nextGroup, nextCategory) {
    const next = new URLSearchParams();
    if (nextGroup) next.set('group', nextGroup);
    if (nextCategory) next.set('category', nextCategory);
    setParams(next, { replace: true });
  }

  const categories = [...new Set(generated.extensions.map((extension) => extension.category))].sort(
    (left, right) => categoryLabel(left).localeCompare(categoryLabel(right)),
  );

  return (
    <div className="catalog-page">
      <header className="page-header">
        <span className="eyebrow">Catalog</span>
        <h1>Extensions</h1>
        <p>
          {generated.stats.extensions} composable capabilities across{' '}
          {generated.stats.categories} categories. Each one declares its prompts,
          contracts, platforms, support probes, and tests.
        </p>
      </header>

      <div className="catalog-toolbar">
        <div className="catalog-search">
          <Search size={16} />
          <input
            type="text"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="Filter by name, capability, or category…"
            aria-label="Filter extensions"
          />
          {query ? (
            <button type="button" className="icon-button" onClick={() => setQuery('')} aria-label="Clear filter">
              <X size={15} />
            </button>
          ) : null}
        </div>
        <span className="catalog-count">
          {extensions.length} of {generated.extensions.length}
        </span>
      </div>

      <div className="filter-block">
        <div className="filter-row">
          <span className="filter-label"><Filter size={14} /> Groups</span>
          <div className="chip-row">
            <button
              type="button"
              className={!group && !category ? 'chip active' : 'chip'}
              onClick={() => setFilter(null, null)}
            >
              All
            </button>
            {CATEGORY_GROUPS.map((item) => (
              <button
                key={item.key}
                type="button"
                className={group === item.key ? 'chip active' : 'chip'}
                onClick={() => setFilter(item.key, null)}
              >
                {item.label}
              </button>
            ))}
          </div>
        </div>
        <div className="filter-row">
          <span className="filter-label">Categories</span>
          <div className="chip-row">
            <button
              type="button"
              className={!category ? 'chip subtle active' : 'chip subtle'}
              onClick={() => setFilter(group, null)}
            >
              All
            </button>
            {categories.map((item) => (
              <button
                key={item}
                type="button"
                className={category === item ? 'chip subtle active' : 'chip subtle'}
                onClick={() => setFilter(group, item)}
              >
                {CATEGORY_META[item]?.label ?? item}
              </button>
            ))}
          </div>
        </div>
      </div>

      {groupMeta ? (
        <div className="filter-summary">
          <Badge tone="blue">{groupLabel(groupMeta.key)}</Badge>
          <span>{groupMeta.categories.map(categoryLabel).join(' · ')}</span>
        </div>
      ) : null}

      {extensions.length ? (
        <div className="extension-grid">
          {extensions.map((extension) => (
            <ExtensionCard key={extension.id} extension={extension} />
          ))}
        </div>
      ) : (
        <div className="empty-state">
          <h2>No extension matches that filter.</h2>
          <p>Try a capability such as “http”, “auth”, or “storage”.</p>
          <button type="button" className="button" onClick={() => { setQuery(''); setFilter(null, null); }}>
            Reset filters
          </button>
        </div>
      )}
    </div>
  );
}
