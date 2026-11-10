import { useEffect, useState } from 'react';
import { Route, Routes } from 'react-router-dom';
import Layout from './components/Layout';
import HomePage from './pages/HomePage';
import DocsHomePage from './pages/DocsHomePage';
import DocPage from './pages/DocPage';
import CatalogPage from './pages/CatalogPage';
import ExtensionPage from './pages/ExtensionPage';
import ExtensionDocPage from './pages/ExtensionDocPage';
import NotFoundPage from './pages/NotFoundPage';

function initialTheme() {
  try {
    const saved = localStorage.getItem('kiln-theme');
    if (saved === 'light' || saved === 'dark') return saved;
  } catch {
    // Ignore private-mode storage errors.
  }
  return window.matchMedia?.('(prefers-color-scheme: light)').matches ? 'light' : 'dark';
}

export default function App() {
  const [theme, setTheme] = useState(initialTheme);

  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    try {
      localStorage.setItem('kiln-theme', theme);
    } catch {
      // Ignore private-mode storage errors.
    }
    document
      .querySelector('meta[name="theme-color"]')
      ?.setAttribute('content', theme === 'dark' ? '#0b1220' : '#f6f8fc');
  }, [theme]);

  return (
    <Routes>
      <Route
        element={
          <Layout
            theme={theme}
            onToggleTheme={() => setTheme((value) => (value === 'dark' ? 'light' : 'dark'))}
          />
        }
      >
        <Route index element={<HomePage />} />
        <Route path="docs" element={<DocsHomePage />} />
        <Route path="docs/*" element={<DocPage />} />
        <Route path="extensions" element={<CatalogPage />} />
        <Route path="extensions/:id" element={<ExtensionPage />} />
        <Route path="extensions/:id/docs/:doc" element={<ExtensionDocPage />} />
        <Route path="*" element={<NotFoundPage />} />
      </Route>
    </Routes>
  );
}
