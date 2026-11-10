import { useContext, useEffect, useMemo, useRef } from 'react';
import { renderMarkdown } from '../lib/markdown';
import { PageMetaContext } from '../lib/page-meta';

export default function Markdown({ markdown, className = '', collectHeadings = true }) {
  const { setHeadings } = useContext(PageMetaContext);
  const ref = useRef(null);
  const { html, headings } = useMemo(() => renderMarkdown(markdown ?? ''), [markdown]);

  useEffect(() => {
    if (collectHeadings) setHeadings(headings);
  }, [collectHeadings, headings, setHeadings]);

  useEffect(() => {
    const root = ref.current;
    if (!root) return undefined;

    const buttons = [];
    for (const pre of root.querySelectorAll('pre')) {
      if (pre.querySelector('.code-copy')) continue;
      pre.classList.add('has-copy');
      const button = document.createElement('button');
      button.type = 'button';
      button.className = 'code-copy';
      button.textContent = 'Copy';
      button.setAttribute('aria-label', 'Copy code');
      button.addEventListener('click', async () => {
        const code = pre.querySelector('code')?.innerText ?? pre.innerText;
        try {
          await navigator.clipboard.writeText(code);
          button.textContent = 'Copied';
          window.setTimeout(() => {
            button.textContent = 'Copy';
          }, 1500);
        } catch {
          button.textContent = 'Failed';
        }
      });
      pre.appendChild(button);
      buttons.push(button);
    }

    return () => {
      for (const button of buttons) button.remove();
    };
  }, [html]);

  return (
    <div
      ref={ref}
      className={`markdown ${className}`.trim()}
      dangerouslySetInnerHTML={{ __html: html }}
    />
  );
}
