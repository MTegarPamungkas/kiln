import { createContext, useContext, useEffect } from 'react';

export const PageMetaContext = createContext({
  headings: [],
  setHeadings: () => {},
});

export const usePageMeta = () => useContext(PageMetaContext);

export function useClearHeadings() {
  const { setHeadings } = usePageMeta();
  useEffect(() => {
    setHeadings([]);
  }, [setHeadings]);
}
