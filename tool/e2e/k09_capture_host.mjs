import { createServer } from 'node:http';
import { randomUUID } from 'node:crypto';
import { mkdir, appendFile, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

// Loopback stand-in for PostHog and Sentry ingestion.
//
// The Android build talks to http://127.0.0.1:<port> through `adb reverse`, so
// every request here is real native SDK traffic. Nothing leaves the machine.
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const stateDir = path.join(root, '.dart_tool', 'k09_capture');
const portArg = process.argv.indexOf('--port');
const port = portArg >= 0 ? Number(process.argv[portArg + 1]) : 8799;

await mkdir(stateDir, { recursive: true });
const logPath = path.join(stateDir, 'requests.jsonl');
await writeFile(logPath, '');

/** @type {{at:number,label:string}[]} */
const marks = [];
/** @type {any[]} */
const requests = [];
let bodySeq = 0;

function vendorOf(requestPath) {
  if (/\/envelope\/?$/.test(requestPath)) return 'sentry';
  if (/\/(i\/v0\/e|batch|e)\/?$/.test(requestPath)) return 'posthog';
  if (requestPath.startsWith('/static') || requestPath.startsWith('/array')) {
    return 'posthog-static';
  }
  return 'other';
}

const server = createServer(async (req, res) => {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  const body = Buffer.concat(chunks);
  const url = new URL(req.url, `http://127.0.0.1:${port}`);

  if (url.pathname === '/__mark') {
    const label = url.searchParams.get('label') ?? 'unlabelled';
    marks.push({ at: Date.now(), label });
    await appendFile(logPath, JSON.stringify({ kind: 'mark', at: Date.now(), label }) + '\n');
    res.writeHead(200, { 'content-type': 'application/json' }).end('{"ok":true}');
    return;
  }

  if (url.pathname === '/__summary') {
    const counts = {};
    for (const entry of requests) {
      counts[entry.vendor] = (counts[entry.vendor] ?? 0) + 1;
    }
    const bodies = {};
    for (const entry of requests) {
      bodies[entry.file] = entry.body.slice(0, 4000);
    }
    res.writeHead(200, { 'content-type': 'application/json' })
      .end(JSON.stringify({ counts, marks, requests, bodies }, null, 2));
    return;
  }

  const vendor = vendorOf(url.pathname);
  const file = `body_${++bodySeq}_${vendor}.txt`;
  const text = body.toString('utf8');
  await writeFile(path.join(stateDir, file), body);
  const entry = {
    at: Date.now(),
    vendor,
    method: req.method,
    path: url.pathname + url.search,
    bytes: body.length,
    userAgent: req.headers['user-agent'] ?? '',
    file,
    body: vendor === 'other' ? '' : text,
  };
  requests.push(entry);
  await appendFile(logPath, JSON.stringify({ ...entry, body: undefined }) + '\n');
  process.stdout.write(
    `${new Date(entry.at).toISOString()} ${vendor.padEnd(14)} ${entry.method} ${entry.path} (${entry.bytes}b)\n`,
  );

  if (vendor === 'sentry') {
    res.writeHead(200, { 'content-type': 'application/json' })
      .end(JSON.stringify({ id: randomUUID() }));
    return;
  }
  if (vendor === 'posthog' || vendor === 'posthog-static') {
    res.writeHead(200, { 'content-type': 'application/json' })
      .end(JSON.stringify({ status: 1 }));
    return;
  }
  res.writeHead(404).end('not found');
});

server.listen(port, '127.0.0.1', () => {
  console.log(`K09 capture host on http://127.0.0.1:${port} (state: ${stateDir})`);
  console.log('Mark a phase with: curl http://127.0.0.1:%d/__mark?label=name', port);
});
