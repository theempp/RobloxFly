// Downloads pinned official releases. No global PATH or Studio plugin changes.
import fs from 'node:fs/promises';
import crypto from 'node:crypto';
const files = [
  ['rojo.zip', 'https://github.com/rojo-rbx/rojo/releases/download/v7.7.0/rojo-7.7.0-windows-x86_64.zip'],
  ['luau.zip', 'https://github.com/luau-lang/luau/releases/download/0.740/luau-windows.zip'],
  ['lune.zip', 'https://github.com/lune-org/lune/releases/download/v0.10.5/lune-0.10.5-windows-x86_64.zip'],
];
await fs.mkdir('tools', { recursive: true });
for (const [name, url] of files) {
  const response = await fetch(url);
  if (!response.ok) throw new Error(`Download failed: ${response.status} ${url}`);
  const data = Buffer.from(await response.arrayBuffer());
  await fs.writeFile(`tools/${name}`, data);
  console.log(`${name}: ${crypto.createHash('sha256').update(data).digest('hex')}`);
}
console.log('Extract tools/rojo.zip to tools/rojo and tools/luau.zip to tools/luau. See README.');
await fs.mkdir('tools/vendor', { recursive: true });
for (const name of ['three.module.js', 'three.core.js']) {
  const response = await fetch(`https://cdn.jsdelivr.net/npm/three@0.180.0/build/${name}`);
  if (!response.ok) throw new Error(`Asset-inspector dependency failed: ${response.status}`);
  await fs.writeFile(`tools/vendor/${name}`, await response.text());
}
const license = await fetch('https://cdn.jsdelivr.net/npm/three@0.180.0/LICENSE');
if (!license.ok) throw new Error('Missing Three.js license');
await fs.writeFile('tools/vendor/LICENSE', await license.text());
