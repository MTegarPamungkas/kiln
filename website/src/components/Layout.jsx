import { useCallback, useEffect, useMemo, useState } from 'react';
import { Link, NavLink, Outlet, useLocation } from 'react-router-dom';
import {
  BookOpen,
  ChevronRight,
  GitBranch,
  Menu,
  Moon,
  Search,
  Sun,
  X,
} from 'lucide-react';
import generated from '../content/generated.json';
import { buildDocsNav } from '../lib/nav';
import { CATEGORY_GROUPS } from '../lib/categories';
import { PageMetaContext } from '../lib/page-meta';
import Logo from './Logo';
import Toc from './Toc';
import SearchDialog from './SearchDialog';

const docsNav = buildDocsNav(generated.docs);

const TOP_LINKS = [
  { label: 'Docs', route: '/docs' },
  { label: 'Extensions', route: '/extensions' },
  { label: 'CLI', route: '/docs/cli/reference' },
];

export default function Layout({ theme, onToggleTheme }) {
  const location = useLocation();
  const [headings, setHeadings] = useState([]);
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);
  const group = new URLSearchParams(location.search).get('group');

  const setStableHeadings = useCallback((next) => setHeadings(next), []);

  useEffect(() => {
    setSidebarOpen(false);
    const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    if (location.hash) {
      const id = decodeURIComponent(location.hash.slice(1));
      window.requestAnimationFrame(() => {
        document.getElementById(id)?.scrollIntoView({
          behavior: reduce ? 'auto' : 'smooth',
          block: 'start',
        });
      });
    } else {
      window.scrollTo({ top: 0, behavior: 'auto' });
    }
  }, [location.pathname, location.hash]);

  useEffect(() => {
    function onKeyDown(event) {
      const isSearch = (event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k';
      if (isSearch) {
        event.preventDefault();
        setSearchOpen((open) => !open);
      }
    }
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, []);

  useEffect(() => {
    document.body.classList.toggle('sidebar-open', sidebarOpen);
    return () => document.body.classList.remove('sidebar-open');
  }, [sidebarOpen]);

  const sidebar = useMemo(
    () => (
      <nav className="sidebar-nav" aria-label="Documentation navigation">
        <NavLink
          to="/docs"
          end
          className={({ isActive }) => `side-home ${isActive ? 'active' : ''}`}
        >
          <BookOpen size={16} />
          Documentation home
        </NavLink>

        {docsNav.slice(0, 1).map((section) => (
          <SidebarSection key={section.label} section={section} />
        ))}

        <div className="nav-group">
          <p className="nav-group-title">Extensions</p>
          <NavLink
            to="/extensions"
            end
            className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}
          >
            All extensions
            <span className="nav-count">{generated.stats.extensions}</span>
          </NavLink>
          {CATEGORY_GROUPS.map((item) => (
            <Link
              key={item.key}
              to={`/extensions?group=${item.key}`}
              className={`nav-link sub ${group === item.key ? 'active' : ''}`}
            >
              {item.label}
              <ChevronRight size={13} />
            </Link>
          ))}
        </div>

        {docsNav.slice(1).map((section) => (
          <SidebarSection key={section.label} section={section} />
        ))}

        <div className="sidebar-meta">
          <span>Kiln v{generated.version ?? '0.1.1'}</span>
          <span>{generated.stats.extensions} extensions · {generated.stats.docs} docs</span>
        </div>
      </nav>
    ),
    [group],
  );

  return (
    <PageMetaContext.Provider value={{ headings, setHeadings: setStableHeadings }}>
      <div className="app-shell">
        <header className="topbar">
          <button
            type="button"
            className="icon-button menu-button"
            onClick={() => setSidebarOpen(true)}
            aria-label="Open navigation"
          >
            <Menu size={18} />
          </button>

          <Link to="/" className="brand" aria-label="Kiln home">
            <Logo size={30} />
            <span className="brand-name">Kiln</span>
            <span className="brand-badge">docs</span>
          </Link>

          <nav className="top-links" aria-label="Primary">
            {TOP_LINKS.map((item) => (
              <Link
                key={item.route}
                to={item.route}
                className={
                  isTopActive(item.route, location.pathname)
                    ? 'top-link active'
                    : 'top-link'
                }
              >
                {item.label}
              </Link>
            ))}
          </nav>

          <div className="top-actions">
            <button
              type="button"
              className="search-trigger"
              onClick={() => setSearchOpen(true)}
              aria-label="Search documentation"
            >
              <Search size={16} />
              <span>Search docs</span>
              <kbd>{navigator.platform?.toLowerCase().includes('mac') ? '⌘' : 'Ctrl'} K</kbd>
            </button>
            <span className="version-pill">v{generated.version ?? '0.1.1'}</span>
            <button
              type="button"
              className="icon-button"
              onClick={onToggleTheme}
              aria-label={`Switch to ${theme === 'dark' ? 'light' : 'dark'} theme`}
            >
              {theme === 'dark' ? <Sun size={17} /> : <Moon size={17} />}
            </button>
            <a
              className="icon-button"
              href="https://github.com/MTegarPamungkas/kiln"
              target="_blank"
              rel="noreferrer"
              aria-label="Kiln on GitHub"
            >
              <GitBranch size={17} />
            </a>
          </div>
        </header>

        <div className="shell-body">
          <aside className={`sidebar ${sidebarOpen ? 'open' : ''}`}>
            <div className="sidebar-mobile-head">
              <span>Navigation</span>
              <button
                type="button"
                className="icon-button"
                onClick={() => setSidebarOpen(false)}
                aria-label="Close navigation"
              >
                <X size={17} />
              </button>
            </div>
            {sidebar}
          </aside>
          {sidebarOpen ? (
            <button
              type="button"
              className="sidebar-scrim"
              aria-label="Close navigation"
              onClick={() => setSidebarOpen(false)}
            />
          ) : null}

          <div className="content-shell">
            <main className="page" key={location.pathname}>
              <Outlet />
            </main>
            <Toc headings={headings} />
          </div>
        </div>

        <footer className="site-footer">
          <div>
            <Logo size={22} />
            <span>Kiln — composable Flutter applications.</span>
          </div>
          <div className="footer-links">
            <Link to="/docs/getting-started">Get started</Link>
            <Link to="/extensions">Extensions</Link>
            <Link to="/docs/cli/reference">CLI</Link>
            <a href="https://github.com/MTegarPamungkas/kiln" target="_blank" rel="noreferrer">
              GitHub
            </a>
          </div>
        </footer>

        <SearchDialog
          open={searchOpen}
          onClose={() => setSearchOpen(false)}
          entries={generated.search}
        />
      </div>
    </PageMetaContext.Provider>
  );
}

function isTopActive(route, pathname) {
  if (route === '/extensions') {
    return pathname === '/extensions' || pathname.startsWith('/extensions/');
  }
  if (route === '/docs') {
    return (
      pathname === '/docs' ||
      (pathname.startsWith('/docs/') && !pathname.startsWith('/docs/cli'))
    );
  }
  return pathname === route || pathname.startsWith(`${route}/`);
}

function SidebarSection({ section }) {
  return (
    <div className="nav-group">
      <p className="nav-group-title">{section.label}</p>
      {section.items.map((item) => (
        <NavLink
          key={item.route}
          to={item.route}
          className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}
        >
          {item.title}
        </NavLink>
      ))}
    </div>
  );
}
