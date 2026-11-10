import { useEffect, useState } from 'react';

export default function Toc({ headings }) {
  const [active, setActive] = useState('');

  useEffect(() => {
    if (!headings?.length) return undefined;
    const elements = headings
      .map((heading) => document.getElementById(heading.id))
      .filter(Boolean);
    if (!elements.length) return undefined;

    const observer = new IntersectionObserver(
      (entries) => {
        const visible = entries
          .filter((entry) => entry.isIntersecting)
          .sort((left, right) => left.boundingClientRect.top - right.boundingClientRect.top);
        if (visible[0]) setActive(visible[0].target.id);
      },
      { rootMargin: '-96px 0px -70% 0px', threshold: [0, 1] },
    );
    for (const element of elements) observer.observe(element);
    return () => observer.disconnect();
  }, [headings]);

  if (!headings?.length) return null;

  return (
    <aside className="toc" aria-label="On this page">
      <p className="toc-title">On this page</p>
      <ul>
        {headings.map((heading) => (
          <li key={heading.id} className={`depth-${heading.depth}`}>
            <a
              href={`#${heading.id}`}
              className={active === heading.id ? 'active' : ''}
              onClick={(event) => {
                event.preventDefault();
                document.getElementById(heading.id)?.scrollIntoView({ behavior: 'smooth' });
                history.replaceState(null, '', `#${heading.id}`);
                setActive(heading.id);
              }}
            >
              {heading.text}
            </a>
          </li>
        ))}
      </ul>
      <button
        type="button"
        className="toc-top"
        onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
      >
        Back to top
      </button>
    </aside>
  );
}
