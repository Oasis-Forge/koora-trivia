// Adds the current-screen screenshots to the design-sync bundle.
//
// The converter copies only .md/.mdx guidelines, so the PNGs are copied here after
// package-build.mjs. The sync anchor's auxSha hashes guidelines/, so it is refreshed
// with the converter's own auxShaFor to keep _ds_sync.json describing exactly what
// gets uploaded.
//
// Run from the repo root after the build: node .design-sync/add-screens.mjs
import { cpSync, mkdirSync, readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const OUT = resolve('ds-bundle');
const SRC = resolve('design-system', 'screens');
const { auxShaFor } = await import(
  pathToFileURL(resolve('.ds-sync', 'lib', 'sync-hashes.mjs')).href
);

const dest = join(OUT, 'guidelines', 'screens');
mkdirSync(dest, { recursive: true });
const pngs = readdirSync(SRC).filter((f) => f.endsWith('.png')).sort();
for (const f of pngs) cpSync(join(SRC, f), join(dest, f));

const syncPath = join(OUT, '_ds_sync.json');
const raw = readFileSync(syncPath, 'utf8');
const sync = JSON.parse(raw);
sync.auxSha = auxShaFor(OUT);
const indent = /^\{\n( +)/.exec(raw)?.[1]?.length ?? 0;
writeFileSync(syncPath, JSON.stringify(sync, null, indent) + (raw.endsWith('\n') ? '\n' : ''));
console.log(`copied ${pngs.length} screenshots; auxSha ${sync.auxSha}`);
