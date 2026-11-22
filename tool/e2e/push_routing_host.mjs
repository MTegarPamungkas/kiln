// Loopback fixture host for the push-routing probe (`--routing`).
//
// Why a host process: the generated probe has no embedded credentials. It reads
// its configuration from `GET /fixture` and posts progress to `POST /report`.
// This process owns that exchange, keeps the server API key in memory, verifies
// the account the app is signed in as, and sends uniquely labelled probe
// messages. Nothing here writes a credential into the repository.
//
// Usage (defaults are for the routing probe fixture):
//   $env:KILN_APPWRITE_ENDPOINT = 'https://appwrite.example/v1'
//   $env:KILN_APPWRITE_PROJECT  = '<project id>'
//   $env:KILN_APPWRITE_API_KEY  = '<server API key>'
//   $env:KILN_APPWRITE_PUSH_ENDPOINT = 'mqtts://push.example:8883'
//   $env:KILN_ROUTING_USER      = '<disposable user id>'
//   node tool/e2e/push_routing_host.mjs --port 8768
//
// Optional:
//   KILN_ROUTING_EMAIL / KILN_ROUTING_PASSWORD  temporary-account login values
//   --state-dir <dir>   reports, log and generated password (default
//                       .dart_tool/push_routing_host)
//   --reset-password    regenerate the disposable user's password through the
//                       server API when it is no longer known, then save it to
//                       <state-dir>/password.txt. Only use this for a throwaway
//                       test user this run owns; never for a personal account.
//
// The phone reaches this process through `adb reverse tcp:<port> tcp:<port>`.
// Admin routes are loopback-only helpers for the operator; the probe itself only
// calls /fixture and /report.

import http from 'node:http';
import { randomBytes } from 'node:crypto';
import { appendFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const args = process.argv.slice(2);
const flag = name => args.includes(name);
const option = (name, fallback) => {
  const index = args.indexOf(name);
  if (index === -1) return fallback;
  const value = args[index + 1];
  if (!value || value.startsWith('--')) throw new Error(`${name} needs a value.`);
  return value;
};

const endpoint = process.env.KILN_APPWRITE_ENDPOINT?.replace(/\/+$/, '');
const project = process.env.KILN_APPWRITE_PROJECT;
const apiKey = process.env.KILN_APPWRITE_API_KEY;
const pushEndpointEnv = process.env.KILN_APPWRITE_PUSH_ENDPOINT;
const userId = process.env.KILN_ROUTING_USER;
if (!endpoint || !project || !apiKey || !pushEndpointEnv || !userId) {
  throw new Error('Set KILN_APPWRITE_ENDPOINT, KILN_APPWRITE_PROJECT, '
    + 'KILN_APPWRITE_API_KEY, KILN_APPWRITE_PUSH_ENDPOINT and KILN_ROUTING_USER.');
}

// Mutable so an operator can point one probe launch at an unreachable broker
// and then restore the real endpoint without restarting this process.
let pushEndpoint = pushEndpointEnv;

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const stateDir = path.resolve(option('--state-dir', path.join(root, '.dart_tool', 'push_routing_host')));
const port = Number(option('--port', '8768'));
if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('Invalid port.');
mkdirSync(stateDir, { recursive: true });

const email = process.env.KILN_ROUTING_EMAIL ?? `${userId}@example.test`;
const reportsFile = path.join(stateDir, 'reports.jsonl');
const logFile = path.join(stateDir, 'host.log');
const passwordFile = path.join(stateDir, 'password.txt');
if (!existsSync(reportsFile)) writeFileSync(reportsFile, '');

// Deliberately no key, password or token is ever logged.
function note(line) {
  const text = `[${new Date().toISOString()}] ${line}\n`;
  appendFileSync(logFile, text);
  process.stdout.write(text);
}

async function admin(route, method = 'GET', body, timeout = 30000) {
  const response = await fetch(endpoint + route, {
    method,
    headers: {
      'X-Appwrite-Project': project,
      'X-Appwrite-Key': apiKey,
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(timeout),
  });
  const text = await response.text();
  let parsed = null;
  try {
    parsed = text ? JSON.parse(text) : null;
  } catch {
    parsed = { raw: text.slice(0, 500) };
  }
  return { status: response.status, body: parsed };
}

let password = process.env.KILN_ROUTING_PASSWORD ?? '';
if (!password && existsSync(passwordFile)) password = readFileSync(passwordFile, 'utf8').trim();
if (flag('--reset-password')) {
  password = `Kiln9!${randomBytes(18).toString('base64url')}`;
  const reset = await admin(`/users/${encodeURIComponent(userId)}/password`, 'PATCH', { password });
  if (reset.status !== 200) throw new Error(`Password reset failed (${reset.status}).`);
  writeFileSync(passwordFile, password);
  note(`reset password for disposable probe user ${userId}`);
}

function json(res, status, body) {
  res.writeHead(status, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' });
  res.end(JSON.stringify(body));
}

async function readBody(req, limit = 1_000_000) {
  let text = '';
  for await (const chunk of req) {
    text += chunk;
    if (text.length > limit) throw new Error('body_too_large');
  }
  return text ? JSON.parse(text) : {};
}

const server = http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url, 'http://127.0.0.1');
    if (url.pathname === '/fixture' && req.method === 'GET') {
      const platform = url.searchParams.get('platform') ?? 'android';
      if (platform !== 'android') return json(res, 400, { error: 'unknown_platform' });
      note('fixture served');
      return json(res, 200, { endpoint, project, userId, email, password, pushEndpoint, phase: 'login' });
    }
    if (url.pathname === '/report' && req.method === 'POST') {
      const body = await readBody(req);
      const record = {
        at: new Date().toISOString(),
        phase: body.phase,
        checks: body.checks ?? [],
        error: body.error ?? null,
      };
      appendFileSync(reportsFile, `${JSON.stringify(record)}\n`);
      note(`report ${record.phase} ${JSON.stringify(record.checks)}`);
      return json(res, 200, { received: true });
    }
    if (url.pathname === '/reports' && req.method === 'GET') {
      const reports = readFileSync(reportsFile, 'utf8')
        .split('\n').filter(Boolean).map(line => JSON.parse(line));
      return json(res, 200, { reports });
    }
    if (url.pathname === '/admin/ping') {
      return json(res, 200, { ok: true, endpoint, project, userId, pushEndpoint });
    }
    if (url.pathname === '/admin/push-endpoint' && req.method === 'POST') {
      const body = await readBody(req);
      if (typeof body.endpoint !== 'string' || !body.endpoint.trim()) {
        return json(res, 400, { error: 'endpoint_required' });
      }
      pushEndpoint = body.endpoint.trim();
      note(`push endpoint overridden for the next probe launch`);
      return json(res, 200, { pushEndpoint });
    }
    if (url.pathname === '/admin/user' && req.method === 'GET') {
      const id = url.searchParams.get('id') ?? userId;
      const result = await admin(`/users/${encodeURIComponent(id)}`);
      if (result.status !== 200) return json(res, result.status, result.body);
      return json(res, 200, {
        id: result.body.$id,
        email: result.body.email,
        name: result.body.name,
        status: result.body.status,
        labels: result.body.labels,
        targets: result.body.targets,
      });
    }
    if (url.pathname === '/admin/users' && req.method === 'GET') {
      const query = new URLSearchParams({ limit: '25' });
      const search = url.searchParams.get('search');
      if (search) query.set('search', search);
      const result = await admin(`/users?${query}`);
      if (result.status !== 200) return json(res, result.status, result.body);
      return json(res, 200, {
        total: result.body.total,
        users: (result.body.users ?? []).map(u => ({ id: u.$id, email: u.email, name: u.name, targets: u.targets })),
      });
    }
    if (url.pathname === '/admin/send' && req.method === 'POST') {
      const body = await readBody(req);
      const recipient = body.userId ?? userId;
      if (!body.title) return json(res, 400, { error: 'title_required' });
      const messageId = `kilnroute_msg_${Date.now().toString(36)}`;
      const payload = {
        messageId,
        title: body.title,
        body: body.body ?? 'Push routing probe',
        users: [recipient],
        data: body.data ?? {},
        draft: false,
      };
      // Pass providerId: null to let Appwrite route through every push provider.
      if (body.providerId !== null) payload.providerId = body.providerId ?? userId;
      const result = await admin('/messaging/messages/push', 'POST', payload);
      note(`sent ${messageId} to ${recipient} (${result.status})`);
      return json(res, result.status, { messageId, response: result.body });
    }
    if (url.pathname === '/admin/message' && req.method === 'GET') {
      const id = url.searchParams.get('id');
      if (!id) return json(res, 400, { error: 'id_required' });
      const result = await admin(`/messaging/messages/${encodeURIComponent(id)}`);
      return json(res, result.status, result.body);
    }
    return json(res, 404, { error: 'not_found' });
  } catch (error) {
    return json(res, 500, { error: 'fixture_failed', type: error?.name ?? 'Error' });
  }
});

await new Promise((resolve, reject) => {
  server.once('error', reject);
  server.listen(port, '127.0.0.1', resolve);
});
note(`routing fixture listening on 127.0.0.1:${port} (state: ${stateDir})`);

for (const signal of ['SIGINT', 'SIGTERM']) {
  process.once(signal, () => server.close(() => process.exit(0)));
}
