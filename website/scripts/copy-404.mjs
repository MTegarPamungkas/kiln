import fs from 'node:fs';
import path from 'node:path';

const dist = path.resolve('dist');
const index = path.join(dist, 'index.html');
const fallback = path.join(dist, '404.html');

if (!fs.existsSync(index)) {
  throw new Error('dist/index.html is missing; run vite build first.');
}

fs.copyFileSync(index, fallback);
console.log('Copied dist/index.html → dist/404.html');
