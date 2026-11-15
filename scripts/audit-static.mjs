import { readdir, readFile, access } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import path from 'node:path';

const root = process.cwd();
const ignored = new Set(['.git', 'node_modules', '.vercel', 'dist', 'build']);
const files = [];

async function walk(dir) {
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      if (!ignored.has(entry.name)) await walk(path.join(dir, entry.name));
    } else if (entry.isFile()) {
      files.push(path.join(dir, entry.name));
    }
  }
}

await walk(root);
const jsFiles = files.filter((file) => file.endsWith('.js') || file.endsWith('.mjs'));
const htmlFiles = files.filter((file) => file.endsWith('.html'));
const failures = [];

for (const file of jsFiles) {
  const result = spawnSync(process.execPath, ['--check', file], { encoding: 'utf8' });
  if (result.status !== 0) {
    failures.push('JavaScript syntax error: ' + path.relative(root, file) + '\n' + (result.stderr || result.stdout));
  }
}

for (const file of htmlFiles) {
  const source = await readFile(file, 'utf8');
  const refs = source.matchAll(/(?:src|href)\s*=\s*(['"])(.*?)\1/gi);
  for (const match of refs) {
    const raw = match[2].trim();
    if (!raw || /^[a-z][a-z0-9+.-]*:/i.test(raw) || raw.startsWith('/') || raw.startsWith('#')) continue;
    const local = raw.split(/[?#]/, 1)[0];
    if (!/\.(?:js|mjs|css|html|json|svg|png|jpe?g|webp|woff2?)$/i.test(local)) continue;
    let decoded;
    try { decoded = decodeURIComponent(local); } catch { decoded = local; }
    const target = path.resolve(path.dirname(file), decoded);
    if (!target.startsWith(root + path.sep)) continue;
    try { await access(target); }
    catch { failures.push('Missing local reference: ' + path.relative(root, file) + ' -> ' + raw); }
  }
}

console.log('Checked ' + jsFiles.length + ' JavaScript files and ' + htmlFiles.length + ' HTML pages.');
if (failures.length) {
  console.error(failures.join('\n\n'));
  process.exitCode = 1;
} else {
  console.log('Static code audit passed: JavaScript parses and local HTML assets resolve.');
}
