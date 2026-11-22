// Drives the K04 browser OAuth run: a real Chrome goes through the probe app,
// GoTrue, and the mock OIDC provider, then the app reports what it got.
//
// Prerequisites (all local, no third-party account):
//   1. local Supabase stack with the `keycloak` provider pointing at the mock
//      (see `supabase_mock_oidc.mjs` and the fixture's config.toml);
//   2. `node tool/e2e/supabase_mock_oidc.mjs --port 8771`;
//   3. `node tool/e2e/serve_supabase_oauth_app.mjs --port 8088`;
//   4. the probe app built: `flutter build web --dart-define=SUPABASE_ANON_KEY=...`.
//
// Playwright is resolved from the current project first, then from the global
// npm root, so a global install works without copying node_modules here.
//
//   node tool/e2e/run_supabase_oauth.mjs
//
// Output is one PASS/FAIL line per assertion; the exit code is non-zero when any
// assertion fails.

import { execSync } from 'node:child_process';
import { readFile, rm } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { join, resolve } from 'node:path';

const args = process.argv.slice(2);
const flag = (name, fallback) => {
  const index = args.indexOf(name);
  return index === -1 ? fallback : args[index + 1];
};

const appUrl = flag('--app', 'http://127.0.0.1:8088/');
const reportsUrl = flag('--reports', 'http://127.0.0.1:8088/reports');
const reportFile = resolve(flag('--report-file', '.dart_tool/k04_oauth/reports.jsonl'));
const oidcUrl = flag('--oidc', 'http://127.0.0.1:8771');
const timeoutMs = Number(flag('--timeout', 90000));
const expectedEmail = flag('--email', 'oauth-user@kiln.local');

function loadPlaywright() {
  const base = createRequire(import.meta.url);
  try {
    return base('playwright');
  } catch {
    const globalRoot = execSync('npm root -g', { encoding: 'utf8' }).trim();
    return base(join(globalRoot, 'playwright'));
  }
}

const failures = [];
let checks = 0;

function check(label, ok, detail) {
  checks += 1;
  if (ok) {
    console.log(`ok   ${label}`);
  } else {
    const suffix = detail === undefined ? '' : ` (${JSON.stringify(detail)})`;
    console.log(`FAIL ${label}${suffix}`);
    failures.push(label);
  }
}

async function readReports() {
  try {
    const raw = await readFile(reportFile, 'utf8');
    return raw
      .split('\n')
      .filter((line) => line.trim().length > 0)
      .map((line) => JSON.parse(line));
  } catch {
    return [];
  }
}

async function waitFor(predicate, timeout) {
  const deadline = Date.now() + timeout;
  while (Date.now() < deadline) {
    if (await predicate()) {
      return true;
    }
    await new Promise((done) => setTimeout(done, 250));
  }
  return false;
}

await rm(reportFile, { force: true });

const { chromium } = loadPlaywright();
const browser = await chromium.launch({ channel: 'chrome', headless: true });
const page = await browser.newPage();
const navigations = [];
const requests = [];
page.on('request', (request) => {
  requests.push(request.url());
});
page.on('framenavigated', (frame) => {
  if (frame === page.mainFrame()) {
    navigations.push(frame.url());
  }
});
page.on('console', (message) => {
  if (message.type() === 'error') {
    console.log('[browser:error]', message.text());
  }
});

try {
  await page.goto(appUrl, { waitUntil: 'domcontentloaded', timeout: 45000 });

  const finished = await waitFor(async () => {
    const reports = await readReports();
    return reports.some((event) =>
      ['note-ok', 'note-failed', 'provider-error', 'exchange-missing', 'init-error'].includes(
        event.event,
      ),
    );
  }, timeoutMs);

  const reports = await readReports();
  const events = reports.map((event) => event.event);
  const byEvent = (name) => reports.find((event) => event.event === name);

  check('probe app reported the flow started', events.includes('redirecting'));
  check('app redirected to the keycloak provider', events.includes('redirecting') && byEvent('redirecting').provider === 'keycloak');
  check('no provider or init error was reported', !events.includes('provider-error') && !events.includes('init-error'), events);
  check('the redirect back exchanged for a session', events.includes('signed-in'), events);
  check('the flow finished before the timeout', finished, events);

  const signedIn = byEvent('signed-in');
  if (signedIn) {
    check('session belongs to the OIDC user', signedIn.email === expectedEmail, signedIn.email);
    check('session carries an access token', signedIn.hasAccessToken === true);
  } else {
    check('session belongs to the OIDC user', false, 'no signed-in event');
    check('session carries an access token', false, 'no signed-in event');
  }

  const note = byEvent('note-ok');
  check('a PostgREST insert under the OAuth session succeeded', Boolean(note), byEvent('note-failed')?.error);
  if (note) {
    check('the inserted row is owned by the OAuth user', note.owner === note.sessionUser, {
      owner: note.owner,
      sessionUser: note.sessionUser,
    });
  }

  // The provider must have been reached through GoTrue, in a browser, with PKCE.
  let hits = null;
  try {
    hits = await (await fetch(`${oidcUrl}/hits`)).json();
  } catch (error) {
    hits = { error: `${error}` };
  }
  check('the mock provider received the authorize request', (hits?.authorize ?? 0) >= 1, hits);
  check('the mock provider exchanged the code', (hits?.token ?? 0) >= 1, hits);
  // PKCE is between the app and GoTrue; the provider side uses the client
  // secret, so the challenge is visible on the GoTrue request, not at the mock.
  const authorizeRequest = requests.find((url) => url.includes('/auth/v1/authorize'));
  check(
    'the app sent a PKCE S256 challenge to GoTrue',
    Boolean(authorizeRequest) &&
      /code_challenge_method=s256/i.test(authorizeRequest) &&
      /code_challenge=[^&]{43,}/.test(authorizeRequest),
    authorizeRequest,
  );
  check(
    'the browser navigated through GoTrue to the provider',
    requests.some((url) => url.includes('/protocol/openid-connect/auth')),
    requests,
  );
  check('the browser returned to the app with the probe redirect', navigations.some((url) => url.includes('attempt=1')), navigations);

  const storageKeys = await page.evaluate(() => Object.keys(window.localStorage));
  check('the PKCE session is persisted in browser storage', storageKeys.some((key) => key.includes('-auth-token')), storageKeys);

  console.log(`${checks} checks, ${failures.length} failed${failures.length === 0 ? ' - browser OAuth holds' : ''}`);
} finally {
  await browser.close();
}

if (failures.length > 0) {
  process.exitCode = 1;
}
