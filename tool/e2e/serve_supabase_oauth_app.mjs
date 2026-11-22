// Static host and report sink for the K04 browser OAuth run.
//
// Serves the probe app's `build/web` and records the JSON events the app posts,
// so the Playwright driver asserts on app-reported facts instead of canvas
// pixels. State stays under `.dart_tool/k04_oauth/` and never holds tokens.
//
//   node tool/e2e/serve_supabase_oauth_app.mjs --root .dart_tool/k04_web_oauth/build/web --port 8088

import { createServer } from 'node:http';
import { appendFile, mkdir, readFile, stat } from 'node:fs/promises';
import { extname, join, normalize, resolve } from 'node:path';

const args = process.argv.slice(2);
const flag = (name, fallback) => {
  const index = args.indexOf(name);
  return index === -1 ? fallback : args[index + 1];
};

const port = Number(flag('--port', process.env.KILN_OAUTH_APP_PORT ?? 8088));
const root = resolve(flag('--root', '.dart_tool/k04_web_oauth/build/web'));
const stateDir = resolve(flag('--state', '.dart_tool/k04_oauth'));
const reportFile = join(stateDir, 'reports.jsonl');

const contentTypes = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.map': 'application/json; charset=utf-8',
};

function send(res, status, body, headers = {}) {
  res.writeHead(status, { 'cache-control': 'no-store', ...headers });
  res.end(body);
}

await mkdir(stateDir, { recursive: true });

const server = createServer(async (req, res) => {
  const url = new URL(req.url, `http://127.0.0.1:${port}`);

  if (url.pathname === '/report' && req.method === 'POST') {
    let data = '';
    for await (const chunk of req) {
      data += chunk;
    }
    let event;
    try {
      event = JSON.parse(data);
    } catch {
      return send(res, 400, 'invalid json');
    }
    const record = { at: new Date().toISOString(), ...event };
    await appendFile(reportFile, `${JSON.stringify(record)}\n`);
    console.log('[report]', JSON.stringify(record));
    return send(res, 200, 'ok', { 'content-type': 'text/plain' });
  }

  if (url.pathname === '/reports') {
    let body = '';
    try {
      body = await readFile(reportFile, 'utf8');
    } catch {
      body = '';
    }
    return send(res, 200, body, { 'content-type': 'application/x-ndjson' });
  }

  if (url.pathname === '/health') {
    return send(res, 200, 'ok', { 'content-type': 'text/plain' });
  }

  // Every other path is the SPA: try the file, fall back to index.html so a
  // redirect back with `?code=` still boots the app.
  const relative = normalize(decodeURIComponent(url.pathname)).replace(/^([/\\])+/, '');
  const candidate = join(root, relative);
  if (!candidate.startsWith(root)) {
    return send(res, 403, 'forbidden');
  }
  try {
    const info = await stat(candidate);
    if (info.isFile()) {
      const type = contentTypes[extname(candidate).toLowerCase()] ?? 'application/octet-stream';
      return send(res, 200, await readFile(candidate), { 'content-type': type });
    }
  } catch {
    // fall through to index.html
  }
  try {
    return send(res, 200, await readFile(join(root, 'index.html')), {
      'content-type': contentTypes['.html'],
    });
  } catch {
    return send(res, 404, 'build/web missing; run flutter build web first');
  }
});

server.listen(port, '127.0.0.1', () => {
  console.log(`[host] serving ${root} on http://127.0.0.1:${port} (reports in ${reportFile})`);
});
