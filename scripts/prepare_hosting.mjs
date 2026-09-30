import { createHash } from 'node:crypto';
import { readdir, readFile, writeFile } from 'node:fs/promises';
import { join, relative } from 'node:path';

const output = join(process.cwd(), 'build', 'web');
const workerPath = join(output, 'pwa_service_worker.js');
const hash = createHash('sha256');

async function addFiles(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  entries.sort((a, b) => a.name.localeCompare(b.name));
  for (const entry of entries) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) {
      await addFiles(path);
    } else if (entry.isFile() && path !== workerPath) {
      hash.update(relative(output, path));
      hash.update('\0');
      hash.update(await readFile(path));
      hash.update('\0');
    }
  }
}

try {
  await readFile(join(output, 'index.html'));
  await addFiles(output);
  const buildId = hash.digest('hex').slice(0, 16);
  const worker = await readFile(workerPath, 'utf8');
  const marker = /petit-depart-shell-(?:__APP_BUILD_ID__|[a-f0-9]{16})/g;
  const matches = worker.match(marker);
  if (matches?.length !== 1) {
    throw new Error('Identifiant de version introuvable dans le service worker.');
  }
  await writeFile(workerPath, worker.replace(marker, `petit-depart-shell-${buildId}`));
  process.stdout.write(`PWA prête pour le déploiement : ${buildId}\n`);
} catch (error) {
  console.error('Construisez d’abord la PWA avec flutter build web --release --no-web-resources-cdn.');
  console.error(error);
  process.exitCode = 1;
}
