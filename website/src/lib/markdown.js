import { marked } from 'marked';
import { markedHighlight } from 'marked-highlight';
import hljs from 'highlight.js/lib/core';
import bash from 'highlight.js/lib/languages/bash';
import css from 'highlight.js/lib/languages/css';
import dart from 'highlight.js/lib/languages/dart';
import http from 'highlight.js/lib/languages/http';
import javascript from 'highlight.js/lib/languages/javascript';
import json from 'highlight.js/lib/languages/json';
import markdownLanguage from 'highlight.js/lib/languages/markdown';
import plaintext from 'highlight.js/lib/languages/plaintext';
import sql from 'highlight.js/lib/languages/sql';
import typescript from 'highlight.js/lib/languages/typescript';
import xml from 'highlight.js/lib/languages/xml';
import yaml from 'highlight.js/lib/languages/yaml';
import DOMPurify from 'dompurify';
import { slugify } from './text';

for (const [name, language] of Object.entries({
  bash,
  css,
  dart,
  http,
  javascript,
  json,
  markdown: markdownLanguage,
  plaintext,
  sql,
  typescript,
  xml,
  yaml,
})) {
  hljs.registerLanguage(name, language);
}

marked.use(
  markedHighlight({
    emptyLangClass: 'hljs',
    langPrefix: 'hljs language-',
    highlight(code, lang) {
      const language = hljs.getLanguage(lang) ? lang : null;
      try {
        return language
          ? hljs.highlight(code, { language }).value
          : hljs.highlightAuto(code).value;
      } catch {
        return code;
      }
    },
  }),
);

marked.setOptions({
  gfm: true,
  breaks: false,
});

export function renderMarkdown(source) {
  const raw = marked.parse(source ?? '', { async: false });
  const doc = new DOMParser().parseFromString(raw, 'text/html');
  const used = new Map();
  const headings = [];

  for (const element of doc.querySelectorAll('h1, h2, h3, h4')) {
    const text = (element.textContent ?? '').trim();
    const base = slugify(text) || 'section';
    const count = used.get(base) ?? 0;
    used.set(base, count + 1);
    const id = count === 0 ? base : `${base}-${count}`;
    element.id = id;

    if (element.tagName !== 'H1') {
      headings.push({
        id,
        text,
        depth: Number(element.tagName.slice(1)),
      });
      const anchor = doc.createElement('a');
      anchor.className = 'heading-anchor';
      anchor.href = `#${id}`;
      anchor.setAttribute('aria-hidden', 'true');
      anchor.textContent = '#';
      element.appendChild(anchor);
    }
  }

  for (const pre of doc.querySelectorAll('pre')) {
    const code = pre.querySelector('code');
    const match = code?.className.match(/language-([\w-]+)/);
    pre.dataset.lang = match?.[1] ?? 'text';
  }

  for (const link of doc.querySelectorAll('a[href^="http"]')) {
    link.target = '_blank';
    link.rel = 'noreferrer noopener';
  }

  const base = import.meta.env.BASE_URL.replace(/\/$/, '');
  if (base) {
    for (const link of doc.querySelectorAll('a[href^="/"]')) {
      const href = link.getAttribute('href');
      if (!href || href.startsWith('//') || href.startsWith(`${base}/`)) continue;
      link.setAttribute('href', `${base}${href}`);
    }
  }

  return {
    html: DOMPurify.sanitize(doc.body.innerHTML, {
      ADD_ATTR: ['target'],
    }),
    headings,
  };
}
