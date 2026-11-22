import http from 'node:http';

// Development-only loopback fixture. No database, filesystem persistence or
// server API key is needed by this backend. Dispose it after the test run.
export async function startPlatformBackend(config) {
  const phases = { android: config.initialPhase ?? 'login', web: config.initialPhase ?? 'login' };
  const reports = [];
  const items = new Map();
  let sequence = 0;
  const server = http.createServer(async (req, res) => {
    res.setHeader('Access-Control-Allow-Origin', req.headers.origin || '*');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PATCH, DELETE, OPTIONS');
    const send = (status, body) => {
      res.writeHead(status, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' });
      res.end(JSON.stringify(body));
    };
    if (req.method === 'OPTIONS') { res.writeHead(204); res.end(); return; }
    try {
      const url = new URL(req.url, 'http://localhost');
      const read = async () => {
        let text = '';
        for await (const chunk of req) {
          text += chunk;
          if (text.length > 65536) throw new Error('body_too_large');
        }
        return text ? JSON.parse(text) : {};
      };
      if (url.pathname === '/fixture' && req.method === 'GET') {
        const platform = url.searchParams.get('platform');
        if (!Object.hasOwn(phases, platform)) return send(400, { error: 'unknown_platform' });
        return send(200, { endpoint: config.endpoint, project: config.project,
          userId: config.userId, email: config.email, password: config.password,
          databaseId: config.databaseId, bucketId: config.bucketId,
          pushEndpoint: config.pushEndpoint,
          phase: phases[platform] });
      }
      if (url.pathname === '/report' && req.method === 'POST') {
        const body = await read();
        reports.push({ platform: body.platform, phase: body.phase,
          checks: body.checks, error: body.error, completedAt: new Date().toISOString() });
        return send(200, { received: true });
      }
      if (!url.pathname.startsWith('/items') && url.pathname !== '/control/push') {
        return send(404, { error: 'not_found' });
      }
      const token = req.headers.authorization?.replace(/^Bearer /, '');
      if (!token) return send(401, { error: 'authentication_required' });
      // Validate the user's Appwrite JWT rather than trusting a fake identity.
      const accountResponse = await fetch(`${config.endpoint}/account`, {
        headers: { 'X-Appwrite-Project': config.project, 'X-Appwrite-JWT': token },
        signal: AbortSignal.timeout(15000),
      });
      if (!accountResponse.ok) return send(401, { error: 'invalid_session' });
      const user = await accountResponse.json();
      if (user.$id !== config.userId) return send(403, { error: 'wrong_test_user' });
      if (url.pathname === '/control/push' && req.method === 'POST') {
        if (!config.publishPush) return send(503, { error: 'push_not_configured' });
        const body = await read();
        if (!['android', 'web', 'background'].includes(body.platform)) {
          return send(400, { error: 'invalid_probe_platform' });
        }
        await config.publishPush(body.platform);
        return send(202, { queued: true });
      }
      const id = url.pathname.split('/')[2];
      if (req.method === 'POST' && !id) {
        const body = await read();
        if (typeof body.title !== 'string') return send(422, { error: 'title_required' });
        const item = { id: String(++sequence), title: body.title, owner: user.$id };
        items.set(item.id, item);
        return send(201, item);
      }
      if (req.method === 'GET' && !id) return send(200, { items: [...items.values()] });
      const item = items.get(id);
      if (!item) return send(404, { error: 'not_found' });
      if (req.method === 'GET') return send(200, item);
      if (req.method === 'PATCH') {
        const body = await read();
        if (typeof body.title !== 'string') return send(422, { error: 'title_required' });
        item.title = body.title;
        return send(200, item);
      }
      if (req.method === 'DELETE') { items.delete(id); return send(200, { deleted: true }); }
      return send(405, { error: 'method_not_allowed' });
    } catch {
      if (!res.headersSent) send(500, { error: 'fixture_request_failed' });
      else res.end();
    }
  });
  await new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(config.port ?? 8767, '127.0.0.1', resolve);
  });
  return { phases, reports, items, server,
    close: () => new Promise(resolve => server.close(resolve)) };
}
