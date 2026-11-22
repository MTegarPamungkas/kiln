// Minimal OIDC provider for the local Supabase browser OAuth run.
//
// It exists so a real browser can complete `signInWithOAuth` against the local
// GoTrue without a third-party account: the authorize endpoint redirects
// straight back with a code, and the token endpoint returns a signed id_token
// the mock's own JWKS verifies. The user is synthetic and disposable.
//
//   node tool/e2e/supabase_mock_oidc.mjs --port 8771
//
// Configure GoTrue (supabase/config.toml) as a keycloak provider pointing at
// http://127.0.0.1:8771 with client_id `kiln-local` and the secret below.
//
// Nothing here is a credential for anything real: the key pair is generated per
// run and the secret is a fixed local default.

import { createServer } from 'node:http';
import { createHash, createSign, generateKeyPairSync, randomUUID } from 'node:crypto';

const args = process.argv.slice(2);
const flag = (name) => {
  const index = args.indexOf(name);
  return index === -1 ? undefined : args[index + 1];
};
const port = Number(flag('--port') ?? process.env.KILN_MOCK_OIDC_PORT ?? 8771);
// GoTrue runs in a container: it must reach this host by an address that also
// works in the browser (the browser follows GoTrue's provider redirect). On
// Docker Desktop the stack's gateway IP is that address.
const bind = flag('--bind') ?? process.env.KILN_MOCK_OIDC_BIND ?? '0.0.0.0';
const issuer = flag('--issuer') ?? process.env.KILN_MOCK_OIDC_ISSUER ?? `http://127.0.0.1:${port}`;
const clientId = process.env.KILN_MOCK_OIDC_CLIENT_ID ?? 'kiln-local';
const clientSecret = process.env.KILN_MOCK_OIDC_SECRET ?? 'kiln-local-secret';
const email = process.env.KILN_MOCK_OIDC_EMAIL ?? 'oauth-user@kiln.local';
const subject = process.env.KILN_MOCK_OIDC_SUBJECT ?? 'kiln-oauth-subject';
const kid = 'kiln-local-key';

const { privateKey, publicKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
const jwk = publicKey.export({ format: 'jwk' });

const codes = new Map();
const hits = { authorize: 0, token: 0, discovery: 0, lastAuthorize: null };
const log = (...parts) => console.log('[oidc]', ...parts);

const b64url = (value) => Buffer.from(value).toString('base64url');

function idToken({ nonce, code }) {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT', kid }));
  const payload = b64url(
    JSON.stringify({
      iss: issuer,
      aud: clientId,
      sub: subject,
      email,
      email_verified: true,
      name: 'Kiln OAuth User',
      preferred_username: 'kiln-oauth',
      nonce,
      sid: code,
      iat: now,
      exp: now + 3600,
    }),
  );
  const signer = createSign('RSA-SHA256');
  signer.update(`${header}.${payload}`);
  const signature = signer.sign(privateKey).toString('base64url');
  return `${header}.${payload}.${signature}`;
}

function send(res, status, body, headers = {}) {
  res.writeHead(status, { 'content-type': 'application/json', ...headers });
  res.end(typeof body === 'string' ? body : JSON.stringify(body));
}

function redirect(res, location) {
  res.writeHead(302, { location });
  res.end();
}

function readBody(req) {
  return new Promise((resolve) => {
    let data = '';
    req.on('data', (chunk) => {
      data += chunk;
    });
    req.on('end', () => resolve(data));
  });
}

const server = createServer(async (req, res) => {
  const url = new URL(req.url, issuer);
  // GoTrue's keycloak provider appends the standard Keycloak endpoints instead
  // of using discovery, so both spellings are served.
  const path = url.pathname
    .replace(/^\/protocol\/openid-connect\/auth$/, '/auth')
    .replace(/^\/protocol\/openid-connect\/token$/, '/token')
    .replace(/^\/protocol\/openid-connect\/certs$/, '/jwks')
    .replace(/^\/protocol\/openid-connect\/userinfo$/, '/userinfo');
  log(req.method, url.pathname);

  if (path === '/.well-known/openid-configuration') {
    hits.discovery += 1;
    return send(res, 200, {
      issuer,
      authorization_endpoint: `${issuer}/auth`,
      token_endpoint: `${issuer}/token`,
      userinfo_endpoint: `${issuer}/userinfo`,
      jwks_uri: `${issuer}/jwks`,
      response_types_supported: ['code'],
      subject_types_supported: ['public'],
      id_token_signing_alg_values_supported: ['RS256'],
      scopes_supported: ['openid', 'email', 'profile'],
      token_endpoint_auth_methods_supported: ['client_secret_basic', 'client_secret_post'],
      claims_supported: ['iss', 'aud', 'sub', 'email', 'email_verified', 'name', 'preferred_username'],
    });
  }

  if (path === '/jwks') {
    return send(res, 200, {
      keys: [{ ...jwk, kid, use: 'sig', alg: 'RS256' }],
    });
  }

  if (path === '/auth') {
    const redirectUri = url.searchParams.get('redirect_uri');
    const state = url.searchParams.get('state');
    const nonce = url.searchParams.get('nonce');
    const code = randomUUID();
    codes.set(code, { redirectUri, nonce });
    hits.authorize += 1;
    hits.lastAuthorize = {
      clientId: url.searchParams.get('client_id'),
      redirectUri,
      scope: url.searchParams.get('scope'),
      hasState: Boolean(state),
      hasNonce: Boolean(nonce),
      codeChallengeMethod: url.searchParams.get('code_challenge_method'),
      hasCodeChallenge: Boolean(url.searchParams.get('code_challenge')),
    };
    log('authorize -> code issued', hits.lastAuthorize);
    const back = new URL(redirectUri);
    back.searchParams.set('code', code);
    if (state) {
      back.searchParams.set('state', state);
    }
    return redirect(res, back.toString());
  }

  if (path === '/hits') {
    return send(res, 200, hits);
  }

  if (path === '/token' && req.method === 'POST') {
    const body = new URLSearchParams(await readBody(req));
    const grantType = body.get('grant_type');
    if (grantType !== 'authorization_code') {
      return send(res, 400, { error: 'unsupported_grant_type' });
    }
    const code = body.get('code');
    const entry = codes.get(code);
    if (!entry) {
      return send(res, 400, { error: 'invalid_grant' });
    }
    codes.delete(code);
    hits.token += 1;
    log('token exchange', { code: createHash('sha256').update(code).digest('hex').slice(0, 12) });
    return send(res, 200, {
      access_token: randomUUID(),
      token_type: 'Bearer',
      expires_in: 3600,
      id_token: idToken({ nonce: entry.nonce, code }),
    });
  }

  if (path === '/userinfo') {
    return send(res, 200, {
      sub: subject,
      email,
      email_verified: true,
      name: 'Kiln OAuth User',
      preferred_username: 'kiln-oauth',
    });
  }

  return send(res, 404, { error: 'not_found' });
});

server.listen(port, bind, () => {
  log(`listening on ${issuer} (client_id ${clientId}, user ${email})`);
});
