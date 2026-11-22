import { spawn } from 'node:child_process';
import { randomBytes } from 'node:crypto';
import { mkdir, rm, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { startPlatformBackend } from './platform_backend.mjs';

// Server credentials are read only by this host-side coordinator. Flutter
// children receive no API key, and test-user credentials stay in host memory.
const endpoint = process.env.KILN_APPWRITE_ENDPOINT?.replace(/\/+$/, '');
const project = process.env.KILN_APPWRITE_PROJECT;
const apiKey = process.env.KILN_APPWRITE_API_KEY;
if (!endpoint || !project || !apiKey) {
  throw new Error('Set KILN_APPWRITE_ENDPOINT, KILN_APPWRITE_PROJECT and KILN_APPWRITE_API_KEY.');
}
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const fixture = path.join(root, '.dart_tool', 'appwrite_platform');
const childEnv = { ...process.env };
delete childEnv.KILN_APPWRITE_API_KEY;
const args = new Set(process.argv.slice(2));
const mode = args.has('--services') ? 'services' : args.has('--push') ? 'push' : 'auth';
if (args.has('--services') && args.has('--push')) throw new Error('Choose --services or --push.');
const platforms = args.has('--android') || args.has('--web')
  ? ['android', 'web'].filter(p => args.has(`--${p}`)) : mode === 'push' ? ['android'] : ['android', 'web'];
if (mode === 'push' && platforms.includes('web')) throw new Error('This push extension supports Android/iOS; browser delivery needs a WebSocket transport.');
const pushEndpoint = process.env.KILN_APPWRITE_PUSH_ENDPOINT;
if (mode === 'push' && !pushEndpoint) throw new Error('Set KILN_APPWRITE_PUSH_ENDPOINT.');
const phases = mode === 'auth' ? ['login', 'restore', 'signed-out'] : [mode];
const device = process.env.KILN_ANDROID_DEVICE || 'emulator-5554';
if (!/^[A-Za-z0-9._:-]+$/.test(device)) throw new Error('Invalid Android device ID.');
const id = `kilnplat_${Date.now().toString(36)}`;
const password = `Kiln9!${randomBytes(24).toString('base64url')}`;
let created = false;
let platformCreated = false;
let backend;
let web;
let cleaning = false;
const abort = new AbortController();
process.once('SIGINT', () => abort.abort());
process.once('SIGTERM', () => abort.abort());
const cleanupErrors = [];
const owned = [];
async function writeOwnership() {
  await mkdir(path.join(root, '.dart_tool'), { recursive: true });
  await writeFile(path.join(root, '.dart_tool/appwrite_probe_ownership.json'),
    JSON.stringify({ runId: id, paths: [...owned,
      ...(created ? [`/users/${id}`] : []),
      ...(platformCreated ? [`/projects/${project}/platforms/${id}`] : [])] }, null, 2));
}

async function admin(route, method = 'GET', body) {
  const response = await fetch(endpoint + route, { method,
    headers: { 'X-Appwrite-Project': project, 'X-Appwrite-Key': apiKey,
      'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
    signal: AbortSignal.timeout(30000) });
  if (!response.ok) throw new Error(`Appwrite admin request failed (${response.status}).`);
  return response.status === 204 ? null : response.json();
}
async function createOwned(route, body, resource) {
  const result = await admin(route, 'POST', body);
  owned.unshift(resource);
  await writeOwnership();
  return result;
}
function start(command, commandArgs, cwd = root) {
  const batch = process.platform === 'win32' && ['flutter', 'dart'].includes(command);
  // Only the Flutter batch launchers need cmd. adb/other executables receive
  // argument arrays directly, preserving project paths containing spaces.
  const quote = value => {
    if (/["\r\n%]/.test(value)) throw new Error('Unsupported batch argument.');
    return `"${value}"`;
  };
  const executable = batch ? (process.env.ComSpec || 'cmd.exe') : command;
  // `dart` and `flutter` are .bat launchers on PATH. Quoting the command name
  // makes cmd resolve the literal name instead of PATHEXT, so only the
  // arguments may be quoted: `cmd /d /s /c "dart "run" "tool/x.dart""`.
  const commandLine = [command, ...commandArgs.map(quote)].join(' ');
  const launchArgs = batch
    ? ['/d', '/s', '/c', `"${commandLine}"`]
    : commandArgs;
  return spawn(executable, launchArgs, { cwd, env: childEnv,
    windowsVerbatimArguments: batch, stdio: ['pipe', 'inherit', 'inherit'],
    signal: cleaning ? undefined : abort.signal });
}
async function run(command, commandArgs, cwd = root) {
  const child = start(command, commandArgs, cwd);
  const code = await new Promise((resolve, reject) => {
    child.once('error', reject); child.once('exit', resolve);
  });
  if (code !== 0) throw new Error(`${command} failed (${code}).`);
}
function forgetReports(platform, phase) {
  for (let index = backend.reports.length - 1; index >= 0; index--) {
    const report = backend.reports[index];
    if (report.platform === platform && report.phase === phase) {
      backend.reports.splice(index, 1);
    }
  }
}
async function waitForReport(platform, phase) {
  const deadline = Date.now() + 240000;
  while (Date.now() < deadline) {
    if (abort.signal.aborted) throw new Error('Platform probe interrupted.');
    const report = backend.reports.find(r => r.platform === platform && r.phase === phase);
    if (report) {
      if (report.error) throw new Error(`${platform}/${phase}: ${report.error}`);
      console.log(`${platform}/${phase}: ${report.checks.length} checks passed`);
      return;
    }
    await new Promise(resolve => setTimeout(resolve, 200));
  }
  throw new Error(`${platform}/${phase}: report timed out.`);
}
let failed;
try {
  await admin('/users', 'POST', { userId: id, email: `${id}@kiln.test`, password,
    name: 'Kiln temporary platform probe' });
  created = true;
  await writeOwnership();
  if (mode === 'services') {
    const permissions = ['create', 'read', 'update', 'delete'].map(verb => `${verb}("user:${id}")`);
    await createOwned('/databases', { databaseId: id, name: 'Kiln temporary service probe' }, `/databases/${id}`);
    await createOwned('/storage/buckets', { bucketId: id, name: 'Kiln temporary service probe',
      permissions, fileSecurity: false, enabled: true, maximumFileSize: 8388608 }, `/storage/buckets/${id}`);
    await admin(`/tablesdb/${id}/tables`, 'POST', { tableId: 'tasks', name: 'Temporary tasks',
      permissions, rowSecurity: false, enabled: true });
    await admin(`/tablesdb/${id}/tables`, 'POST', { tableId: 'denied', name: 'Denied tasks',
      permissions: [], rowSecurity: false, enabled: true });
    await admin(`/tablesdb/${id}/tables/tasks/columns/string`, 'POST', { key: 'title', size: 256, required: true });
    await admin(`/tablesdb/${id}/tables/tasks/columns/boolean`, 'POST', { key: 'done', required: true });
    const deadline = Date.now() + 90000;
    while (true) {
      const columns = await admin(`/tablesdb/${id}/tables/tasks/columns`);
      if (columns.columns.every(c => c.status === 'available')) break;
      if (Date.now() > deadline) throw new Error('Temporary schema readiness timed out.');
      await new Promise(resolve => setTimeout(resolve, 500));
    }
    await admin(`/tablesdb/${id}/tables/tasks/indexes`, 'POST', { key: 'title_key', type: 'key', columns: ['title'] });
  }
  if (mode === 'push') {
    await createOwned('/messaging/providers/appwrite', { providerId: id,
      name: 'Kiln temporary native push probe', enabled: true }, `/messaging/providers/${id}`);
  }
  backend = await startPlatformBackend({ endpoint, project, userId: id,
    email: `${id}@kiln.test`, password, initialPhase: phases[0],
    databaseId: mode === 'services' ? id : undefined,
    bucketId: mode === 'services' ? id : undefined, pushEndpoint,
    publishPush: mode !== 'push' ? undefined : async platform => {
      const messageId = `kilnmsg_${Date.now().toString(36)}`;
      await createOwned('/messaging/messages/push', { messageId,
        title: `Kiln ${platform} push probe`, body: 'Functional delivery check',
        users: [id], data: { probe: platform, run: id, route: '/probe' }, draft: false },
      `/messaging/messages/${messageId}`);
    } });
  if (platforms.includes('android')) {
    const existing = await admin(`/projects/${project}/platforms`);
    if (!existing.platforms.some(p => p.applicationId === 'dev.kiln.e2e_appwrite' ||
        p.key === 'dev.kiln.e2e_appwrite')) {
      await admin(`/projects/${project}/platforms`, 'POST', { platformId: id,
        type: 'flutter-android', name: 'Kiln temporary Android probe',
        key: 'dev.kiln.e2e_appwrite' });
      platformCreated = true;
      await writeOwnership();
    }
  }
  await run('dart', ['run', 'tool/appwrite_platform_probe.dart',
    ...(mode === 'auth' ? [] : [`--${mode}`])]);
  await run('flutter', ['pub', 'get'], fixture);
  // Switching probe modes rewrites lib/main.dart, but Flutter's Gradle kernel
  // task can stay up-to-date (the generated depfile contains absolute paths with
  // spaces). Drop the kernel intermediates so the rendered main.dart is really
  // compiled instead of installing the previous mode's APK.
  await rm(path.join(fixture, '.dart_tool', 'flutter_build'), {
    recursive: true, force: true });
  await rm(path.join(fixture, 'build', 'app', 'intermediates', 'flutter'), {
    recursive: true, force: true });
  if (platforms.includes('android')) {
    await run('adb', ['-s', device, 'reverse', 'tcp:8767', 'tcp:8767']);
    await run('flutter', ['build', 'apk', '--debug'], fixture);
    await run('adb', ['-s', device, 'install', '-r',
      path.join(fixture, 'build/app/outputs/flutter-apk/app-debug.apk')]);
    for (const phase of phases) {
      // Stop the old application first. It polls the phase endpoint, and if the
      // phase changes while it is still alive it reports the new phase with an
      // error ("Unknown phase") before the freshly installed build starts.
      await run('adb', ['-s', device, 'shell', 'am', 'force-stop', 'dev.kiln.e2e_appwrite']);
      forgetReports('android', phase);
      backend.phases.android = phase;
      await run('adb', ['-s', device, 'shell', 'am', 'start', '-n',
        'dev.kiln.e2e_appwrite/.MainActivity']);
      await waitForReport('android', phase);
    }
  }
  if (platforms.includes('web')) {
    web = start('flutter', ['run', '-d', 'chrome', '--web-port', '7357',
      '--web-hostname', 'localhost'], fixture);
    web.stdin.on('error', () => {});
    web.once('error', () => { abort.abort(); });
    for (const phase of phases) {
      forgetReports('web', phase);
      backend.phases.web = phase;
      if (phase !== phases[0]) web.stdin.write('R');
      await waitForReport('web', phase);
    }
  }
} catch (error) {
  failed = error.message;
  console.error(failed);
  process.exitCode = 1;
} finally {
  cleaning = true;
  if (web && web.exitCode === null) {
    web.stdin.write('q');
    await Promise.race([new Promise(resolve => web.once('exit', resolve)),
      new Promise(resolve => setTimeout(resolve, 10000))]);
    if (web.exitCode === null) web.kill();
  }
  if (created) {
    try { await admin(`/users/${id}`, 'DELETE'); }
    catch { cleanupErrors.push(`temporary_user:${id}`); }
  }
  for (const resource of owned) {
    try { await admin(resource, 'DELETE'); }
    catch { cleanupErrors.push(resource); }
  }
  if (platformCreated) {
    try { await admin(`/projects/${project}/platforms/${id}`, 'DELETE'); }
    catch { cleanupErrors.push(`temporary_platform:${id}`); }
  }
  if (platforms.includes('android')) {
    try { await run('adb', ['-s', device, 'reverse', '--remove', 'tcp:8767']); }
    catch { /* The listener may already be gone; that is still clean. */ }
  }
  if (backend) await backend.close();
  await mkdir(path.join(root, '.dart_tool'), { recursive: true });
  await writeFile(path.join(root, '.dart_tool', mode === 'auth'
      ? 'appwrite_platform_result.json' : `appwrite_${mode}_platform_result.json`),
    JSON.stringify({ completedAt: new Date().toISOString(), platforms,
      reports: backend?.reports ?? [], error: failed ?? null,
      cleanupSucceeded: cleanupErrors.length === 0, cleanupErrors }, null, 2));
  if (cleanupErrors.length) process.exitCode = 1;
  else await writeFile(path.join(root, '.dart_tool/appwrite_probe_ownership.json'),
    JSON.stringify({ runId: id, paths: [], cleanupSucceeded: true }, null, 2));
}
