// Local geometry inspector. Serves this project only, read-only.
import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
const root=process.cwd();
http.createServer(async(req,res)=>{
  try {
    const url=new URL(req.url,'http://127.0.0.1');
    const file=path.resolve(root, '.'+decodeURIComponent(url.pathname==='/'?'/tools/preview.html':url.pathname));
    if(!file.startsWith(root+path.sep)){res.writeHead(403);res.end();return;}
    const body=await fs.readFile(file);const ext=path.extname(file);
    res.setHeader('Content-Type',({'.html':'text/html','.js':'text/javascript','.json':'application/json'})[ext]||'application/octet-stream');
    res.end(body);
  } catch {res.writeHead(404);res.end('Not found');}
}).listen(8765,'127.0.0.1',()=>console.log('Asset inspector: http://127.0.0.1:8765 — offline geometry, not Roblox rendering.'));
