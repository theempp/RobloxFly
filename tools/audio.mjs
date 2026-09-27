// Original deterministic synthesized audio, 44.1 kHz PCM. No samples or third-party music.
import fs from 'node:fs/promises';
const rate = 44100;
let seed = 874291;
const noise = () => { seed = (1664525 * seed + 1013904223) >>> 0; return seed / 2147483648 - 1; };
const tau = 2 * Math.PI;
const tone = (f,t) => Math.sin(tau*f*t);
const layers = {
  Hangar: { duration: 8, loop: true, fn: (t,n) => 0.15*n + 0.12*tone(60,t) + 0.04*tone(120,t) },
  Turbine: { duration: 8, loop: true, fn: (t,n) => 0.2*n + 0.12*tone(150,t) + 0.055*tone(450,t) + 0.03*tone(920,t) },
  Wind: { duration: 8, loop: true, fn: (t,n) => n*0.35*(0.65+0.12*tone(0.5,t)) },
  Phone: { duration: 1.7, fn: t => (tone(660,t)+0.4*tone(880,t))*0.18*Math.max(0,Math.sin(tau*2*t)) },
  Door: { duration: 1.3, fn: (t,n) => n*0.25*Math.sin(Math.PI*t/1.3) + 0.12*tone(80,t)*Math.exp(-Math.pow((t-1.1)*30,2)) },
  Service: { duration: 1.3, fn: t => 0.3*(tone(660,t)*Math.exp(-5*t)+tone(880,t)*Math.exp(-5*Math.max(0,t-.22))*(t>.22?1:0)) },
  Touchdown: { duration: 1.5, fn: (t,n) => 0.5*(n*0.5+tone(55,t)*0.4)*Math.exp(-t*5) },
  Gear: { duration: 1.6, fn: (t,n) => Math.sin(Math.PI*t/1.6)*(n*0.18+tone(120,t)*0.15) },
  Results: { duration: 3, fn: t => [440,550,660,880].reduce((v,f,i)=>v+(t>i*.16?tone(f,t)*0.13*Math.exp(-1.8*(t-i*.16)):0),0) },
};
await fs.mkdir('assets/audio', {recursive:true});
for (const [name, {duration,loop,fn}] of Object.entries(layers)) {
  const count = Math.floor(rate*duration); const pcm = Buffer.alloc(44+count*2);
  pcm.write('RIFF',0);pcm.writeUInt32LE(pcm.length-8,4);pcm.write('WAVEfmt ',8);pcm.writeUInt32LE(16,16);
  pcm.writeUInt16LE(1,20);pcm.writeUInt16LE(1,22);pcm.writeUInt32LE(rate,24);pcm.writeUInt32LE(rate*2,28);
  pcm.writeUInt16LE(2,32);pcm.writeUInt16LE(16,34);pcm.write('data',36);pcm.writeUInt32LE(count*2,40);
  let low=0;
  for(let i=0;i<count;i++){const t=i/rate; low=low*.91+noise()*.09; const fade=Math.min(1,t/.03,(duration-t)/.06);const v=fn(t,low)*Math.max(0,fade);pcm.writeInt16LE(Math.round(Math.max(-.95,Math.min(.95,v))*32767),44+i*2);}
  await fs.writeFile(`assets/audio/${name}.wav`,pcm);
}
console.log('Authored 9 original WAV layers. Upload permissioned IDs before Roblox playback.');
