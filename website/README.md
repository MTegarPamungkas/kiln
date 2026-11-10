# Kiln documentation site

A Vite + React documentation site for Kiln. The content is generated from the
repository at build time:

- `docs/**/*.md` becomes the guide, concept, CLI, guide, and ADR pages.
- every `extensions/*/extension.yaml` becomes a catalog entry with prompts,
  capabilities, platforms, dependencies, native setup, and compatibility.
- every `extensions/*/README.md` and `extensions/*/docs/*.md` becomes the
  extension overview and topic pages.
- all markdown links between those files are rewritten to site routes.

## Run

```bash
cd website
npm install
npm run dev
```

`npm run dev` and `npm run build` run `npm run content` first. Open the printed
local URL (default `http://localhost:5173`).

## Build

```bash
npm run build
npm run preview
```

The production build uses `base: '/'` and a browser history router. Deploying to
a static host needs an SPA fallback to `index.html`; `public/_redirects` covers
Netlify/Cloudflare Pages style hosts.

## GitHub Pages

```bash
npm run deploy
```

`build:pages` builds with `--base=/kiln/`, copies `index.html` to `404.html` for
deep links, and `gh-pages` pushes the `dist/` folder to the `gh-pages` branch.
The repository Pages source is the `gh-pages` branch at `/`. The published URL
for this repository is `https://mtegarpamungkas.github.io/kiln/`.

## Structure

| Path | Purpose |
| --- | --- |
| `scripts/generate-content.mjs` | Reads docs, manifests, and extension markdown into `src/content/generated.json` |
| `src/lib/markdown.js` | Marked + highlight.js rendering, heading IDs, link safety, sanitization |
| `src/lib/categories.js` | Category labels, groups, and icon mapping |
| `src/components/Layout.jsx` | Top bar, sidebar, search, TOC, theme, responsive shell |
| `src/pages/` | Home, docs index, doc page, catalog, extension detail, extension docs |
| `src/styles.css` | Zorin-inspired dark/light design system |

Search is built from the generated docs, extension metadata, and markdown text
with Fuse.js. `Ctrl/Cmd + K` opens it.

The generated `src/content/generated.json` is intentionally ignored. Run
`npm run content` whenever the repository docs or extension manifests change, or
use `npm run dev` / `npm run build`, which do it automatically.
