import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const websiteDir = path.resolve(scriptDir, '..');
const repoRoot = path.resolve(websiteDir, '..');
const dist = path.join(websiteDir, 'dist');

if (!fs.existsSync(path.join(dist, 'index.html'))) {
  throw new Error('dist/index.html is missing; run npm run build:pages first.');
}

const remote = execFileSync('git', ['remote', 'get-url', 'origin'], {
  cwd: repoRoot,
  encoding: 'utf8',
}).trim();
const temp = fs.mkdtempSync(path.join(os.tmpdir(), 'kiln-pages-'));

function git(args) {
  execFileSync('git', args, { cwd: temp, stdio: 'inherit' });
}

try {
  fs.cpSync(dist, temp, { recursive: true });
  fs.writeFileSync(path.join(temp, '.nojekyll'), '');
  git(['init', '-q']);
  git(['checkout', '-q', '-b', 'gh-pages']);
  git(['add', '-A']);
  git(['commit', '-q', '-m', 'docs: deploy Kiln documentation site']);
  git(['remote', 'add', 'origin', remote]);
  git(['push', 'origin', 'gh-pages', '--force']);
  console.log('Published to https://mtegarpamungkas.github.io/kiln/');
} finally {
  fs.rmSync(temp, { recursive: true, force: true });
}
