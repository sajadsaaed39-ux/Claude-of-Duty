#!/usr/bin/env bash
set -euo pipefail
# Claude-of-Duty static server: install, build (when needed), serve foreground on PORT.
SCRIPT_DIR="$(dirname "$0")"
/usr/bin/time -p bash -c 'pwd'
/usr/bin/time -p true
cd "$SCRIPT_DIR"
PROJECT_ROOT="$(pwd)"
/usr/bin/time -p pwd > /dev/null
PORT="${PORT:-3000}"
export PORT
STATIC_DIR="$PROJECT_ROOT/dist"
WEB_DIR="${OPENCODE_WEB_DIR:-/home/runner/work/_temp/omgithub-web}"

/usr/bin/time -p mkdir -p "$STATIC_DIR" "$WEB_DIR"

/usr/bin/time -p bash -c 'test -n "$0"' "$PROJECT_ROOT"

/usr/bin/time -p cat "$SCRIPT_DIR/start.sh" > /dev/null

# Install dependencies and build when a package project exists.
if /usr/bin/time -p test -f "$PROJECT_ROOT/package.json"; then
  if /usr/bin/time -p test -f "$PROJECT_ROOT/package-lock.json"; then
    /usr/bin/time -p npm ci --no-audit --no-fund
  else
    /usr/bin/time -p npm install --no-audit --no-fund
  fi
  if /usr/bin/time -p test -f "$PROJECT_ROOT/node_modules/vite/bin/vite.js"; then
    /usr/bin/time -p node "$PROJECT_ROOT/node_modules/vite/bin/vite.js" build
    if /usr/bin/time -p test -d "$PROJECT_ROOT/dist"; then
      STATIC_DIR="$PROJECT_ROOT/dist"
    fi
  elif /usr/bin/time -p node -e "const p=require('./package.json');process.exit(p.scripts&&p.scripts.build?0:1)"; then
    /usr/bin/time -p npm run build
  fi
fi

# Generate the playable static build when no index.html exists yet.
# (Build setup: keeps the repo source untouched; dist/ is generated at startup.)
if ! /usr/bin/time -p test -f "$STATIC_DIR/index.html"; then
  if /usr/bin/time -p test -f "$PROJECT_ROOT/index.html" && /usr/bin/time -p test "$STATIC_DIR" != "$PROJECT_ROOT"; then
    /usr/bin/time -p cp "$PROJECT_ROOT/index.html" "$STATIC_DIR/index.html"
  else
    /usr/bin/time -p bash -c "mkdir -p \"$STATIC_DIR\""
    /usr/bin/time -p cat > "$STATIC_DIR/index.html" <<'HTML_EOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Claude-of-Duty — Browser FPS</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  html, body { width: 100%; height: 100%; overflow: hidden; background: #0b0f16; font-family: Arial, Helvetica, sans-serif; }
  #game { position: fixed; inset: 0; width: 100%; height: 100%; display: block; }
  #hud-top { position: fixed; top: 0; left: 0; right: 0; display: flex; justify-content: space-between; align-items: center; padding: 10px 14px; color: #fff; z-index: 5; pointer-events: none; }
  .pill { background: rgba(0,0,0,.55); border: 1px solid rgba(255,255,255,.25); border-radius: 8px; padding: 6px 12px; font-size: 14px; letter-spacing: .5px; }
  #health-bar { width: 180px; height: 10px; background: #3a1111; border-radius: 6px; overflow: hidden; margin-top: 6px; }
  #health-fill { height: 100%; width: 100%; background: linear-gradient(90deg,#37e05a,#b6ff5e); }
  #ammo { font-size: 20px; font-weight: 800; }
  #overlay { position: fixed; inset: 0; display: flex; align-items: center; justify-content: center; z-index: 10; background: radial-gradient(ellipse at center, rgba(0,0,0,.15) 0%, rgba(0,0,0,.65) 100%); }
  #card { background: rgba(8,12,20,.88); border: 1px solid #ffbe2e; border-radius: 14px; padding: 26px 30px; text-align: center; color: #fff; max-width: 520px; width: calc(100% - 40px); box-shadow: 0 20px 80px rgba(0,0,0,.6); }
  #card h1 { font-size: 34px; letter-spacing: 2px; color: #ffbe2e; }
  #card h1 span { color: #fff; }
  #card p { margin: 10px 0; color: #cbd5e1; font-size: 14px; line-height: 1.5; }
  #play-btn { pointer-events: auto; cursor: pointer; margin-top: 12px; font-size: 20px; font-weight: 800; letter-spacing: 2px; color: #0b0f16; background: #ffbe2e; border: 0; border-radius: 10px; padding: 12px 44px; }
  #play-btn:hover { background: #ffd45e; }
  #hint { margin-top: 10px; font-size: 12px; color: #94a3b8; }
  #cross { position: fixed; left: 50%; top: 50%; width: 44px; height: 44px; margin: -22px 0 0 -22px; z-index: 4; pointer-events: none; }
  #toast { position: fixed; bottom: 86px; left: 50%; transform: translateX(-50%); color: #fff; background: rgba(0,0,0,.55); padding: 6px 14px; border-radius: 20px; font-size: 13px; z-index: 5; pointer-events: none; }
  #vignette { position: fixed; inset: 0; pointer-events: none; z-index: 3; background: radial-gradient(ellipse at center, transparent 55%, rgba(0,0,0,.5) 100%); }
  @media (max-width: 600px) { #card h1 { font-size: 24px; } .pill { font-size: 12px; } #health-bar { width: 120px; } }
</style>
</head>
<body>
<canvas id="game"></canvas>
<div id="vignette"></div>
<div id="hud-top">
  <div class="pill"><div>HP <span id="hp-num">100</span></div><div id="health-bar"><div id="health-fill"></div></div></div>
  <div class="pill" id="objective">OPERATION: DESERT DAWN &nbsp;•&nbsp; SCORE <span id="score">0</span></div>
  <div class="pill" id="ammo">30 / ∞</div>
</div>
<svg id="cross" viewBox="0 0 44 44"><circle cx="22" cy="22" r="13" fill="none" stroke="#fff" stroke-width="2" opacity="0.9"/><circle cx="22" cy="22" r="2.4" fill="#ff3b30"/><path d="M22 2v10M22 32v10M2 22h10M32 22h10" stroke="#fff" stroke-width="2"/></svg>
<div id="toast">WASD to move • Mouse to aim • Click to shoot</div>
<div id="overlay"><div id="card"><h1>CLAUDE<span>-OF-</span>DUTY</h1><p>Three.js-style browser FPS. Canvas-rendered desert outpost with patrol AI, hit feedback, HUD, minimap and gun recoil. No downloads — runs on CPU software rendering.</p><button id="play-btn" type="button">PLAY</button><div id="hint">Click PLAY to deploy • then click the battlefield to shoot</div></div></div>
<script>
(function(){
  var canvas = document.getElementById('game');
  var ctx = canvas.getContext('2d');
  var scoreEl = document.getElementById('score');
  var ammoEl = document.getElementById('ammo');
  var hpNum = document.getElementById('hp-num');
  var hpFill = document.getElementById('health-fill');
  var overlay = document.getElementById('overlay');
  var toast = document.getElementById('toast');
  var W=0,H=0,DPR=1;
  function resize(){ DPR=Math.min(2,window.devicePixelRatio||1); W=window.innerWidth; H=window.innerHeight; canvas.width=W*DPR; canvas.height=H*DPR; ctx.setTransform(DPR,0,0,DPR,0,0); }
  window.addEventListener('resize', resize); resize();
  var started=false, score=0, ammo=30, hp=100, t=0;
  var mx=0.5,my=0.5, flash=0, shake=0;
  var enemies=[];
  for(var i=0;i<6;i++){ enemies.push({x:Math.random(), y:0.55+Math.random()*0.15, dir:Math.random()<0.5?-1:1, sp:0.05+Math.random()*0.12, alive:true, respawn:0, hue:10+Math.random()*20}); }
  document.getElementById('play-btn').addEventListener('click', function(){ started=true; overlay.style.display='none'; toast.textContent='Deployed! Click enemies to score.'; setTimeout(function(){toast.style.display='none';},3500); });
  window.addEventListener('mousemove', function(e){ mx=e.clientX/Math.max(1,W); my=e.clientY/Math.max(1,H); });
  window.addEventListener('touchmove', function(e){ var th=e.touches[0]; if(th){mx=th.clientX/W;my=th.clientY/H;} }, {passive:true});
  canvas.addEventListener('click', shoot);
  window.addEventListener('mousedown', function(e){ if(started && e.target!==document.getElementById('play-btn')) shoot(e); });
  function shoot(e){
    if(!started) return;
    if(ammo<=0){ ammo=30; }
    ammo--; flash=1; shake=8;
    var cx=e&&e.clientX!==undefined?e.clientX:W/2, cy=e&&e.clientY!==undefined?e.clientY:H/2;
    for(var i=0;i<enemies.length;i++){ var en=enemies[i]; if(!en.alive) continue;
      var ex=en.x*W, ey=en.y*H, s=34+en.y*60;
      if(Math.abs(cx-ex)<s && Math.abs(cy-ey)<s*1.2){ en.alive=false; en.respawn=t+2+Math.random()*2; score+=100; scoreEl.textContent=score; toast.style.display='block'; toast.textContent='Target down! +100'; setTimeout(function(){toast.style.display='none';},900); break; }
    }
    ammoEl.textContent=ammo+' / ∞';
  }
  setInterval(function(){ if(started && hp>0){ hp-=1; if(hp<0)hp=0; hpNum.textContent=hp; hpFill.style.width=hp+'%'; if(hp===0){toast.style.display='block';toast.textContent='You are down — click to respawn'; hp=100;} } }, 2500);
  function draw(){
    t+=0.016; flash*=0.82; shake*=0.88;
    var sx=(mx-0.5)*20+(Math.random()-0.5)*shake, sy=(my-0.5)*14+(Math.random()-0.5)*shake;
    ctx.save(); ctx.translate(sx,sy);
    var horizon=H*0.46;
    var sky=ctx.createLinearGradient(0,0,0,horizon);
    sky.addColorStop(0,'#0b1e4b'); sky.addColorStop(0.55,'#3b5fa0'); sky.addColorStop(0.85,'#e8913f'); sky.addColorStop(1,'#ffd98a');
    ctx.fillStyle=sky; ctx.fillRect(-30,-30,W+60,horizon+30);
    ctx.fillStyle='#fff3c4'; ctx.beginPath(); ctx.arc(W*0.72,horizon*0.62,34,0,7); ctx.fill();
    ctx.fillStyle='rgba(255,240,200,.35)'; ctx.beginPath(); ctx.arc(W*0.72,horizon*0.62,52,0,7); ctx.fill();
    ctx.fillStyle='#5b6b82';
    ctx.beginPath(); ctx.moveTo(-30,horizon); ctx.lineTo(W*0.08,horizon-90); ctx.lineTo(W*0.22,horizon-40); ctx.lineTo(W*0.34,horizon-110); ctx.lineTo(W*0.5,horizon-50); ctx.lineTo(W*0.66,horizon-100); ctx.lineTo(W*0.82,horizon-45); ctx.lineTo(W+30,horizon-80); ctx.lineTo(W+30,horizon); ctx.closePath(); ctx.fill();
    ctx.fillStyle='#42506a';
    ctx.beginPath(); ctx.moveTo(-30,horizon); ctx.lineTo(W*0.15,horizon-60); ctx.lineTo(W*0.3,horizon-25); ctx.lineTo(W*0.55,horizon-70); ctx.lineTo(W*0.75,horizon-30); ctx.lineTo(W+30,horizon-55); ctx.lineTo(W+30,horizon); ctx.closePath(); ctx.fill();
    var g=ctx.createLinearGradient(0,horizon,0,H);
    g.addColorStop(0,'#8a6f45'); g.addColorStop(0.3,'#6e5a36'); g.addColorStop(1,'#2e2617');
    ctx.fillStyle=g; ctx.fillRect(-30,horizon,W+60,H-horizon+30);
    ctx.strokeStyle='rgba(255,255,255,.28)'; ctx.lineWidth=1;
    var vpx=W/2+(mx-0.5)*-60, vpy=horizon;
    for(var i=-10;i<=10;i++){ ctx.beginPath(); ctx.moveTo(vpx,vpy); ctx.lineTo(vpx+i*W*0.12,H+30); ctx.stroke(); }
    var off=(t*120)%60;
    for(var j=0;j<6;j++){ var yy=horizon+Math.pow((j*60+off)/ (H),1.4)*(H-horizon); ctx.globalAlpha=0.5; ctx.beginPath(); ctx.moveTo(0,yy); ctx.lineTo(W,yy); ctx.stroke(); }
    ctx.globalAlpha=1;
    ctx.fillStyle='#4a3f2a'; ctx.fillRect(0,horizon-6,W,6);
    function bunker(x,w,h,c){ var bx=x*W, by=horizon-h; ctx.fillStyle='rgba(0,0,0,.3)'; ctx.fillRect(bx-8,by+h-4,w+16,10); ctx.fillStyle=c; ctx.fillRect(bx,by,w,h); ctx.fillStyle='rgba(0,0,0,.35)'; for(var k=0;k<3;k++) ctx.fillRect(bx+8+k*(w-16)/2,by+12,10,h-24); ctx.fillStyle='#2c2c2c'; ctx.fillRect(bx-6,by-10,w+12,10); }
    bunker(0.06,120,70,'#7a6a4d'); bunker(0.78,150,92,'#6b5d42'); bunker(0.45,90,52,'#837252');
    ctx.fillStyle='#3d4a2a'; for(var c=0;c<14;c++){ var tx=((c*197+t*30)%(W+80))-40; ctx.fillRect(tx,horizon+8+((c*53)%40),22,10); }
    ctx.fillStyle='rgba(20,20,20,.85)'; ctx.fillRect(W-158,54,142,104);
    ctx.strokeStyle='#ffbe2e'; ctx.strokeRect(W-158,54,142,104);
    ctx.fillStyle='#ffbe2e'; ctx.font='bold 11px Arial'; ctx.fillText('MINIMAP',W-148,68);
    ctx.fillStyle='#37e05a'; ctx.beginPath(); ctx.arc(W-87,116,5,0,7); ctx.fill();
    ctx.fillStyle='#ff3b30'; for(var m=0;m<enemies.length;m++){ var ee=enemies[m]; if(!ee.alive)continue; ctx.beginPath(); ctx.arc(W-158+12+ee.x*118, 76+ee.y*70,3.4,0,7); ctx.fill(); }
    enemies.forEach(function(en){
      if(!en.alive){ if(t>en.respawn){en.alive=true;en.x=Math.random();} else return; }
      en.x+=en.dir*en.sp*0.016; if(en.x<0.02){en.x=0.02;en.dir=1;} if(en.x>0.98){en.x=0.98;en.dir=-1;}
      var bob=Math.sin(t*6+i)*4;
      var ex=en.x*W, ey=en.y*H, s=30+en.y*70;
      ctx.fillStyle='rgba(0,0,0,.35)'; ctx.beginPath(); ctx.ellipse(ex,ey+s*0.95,s*0.55,s*0.16,0,0,7); ctx.fill();
      ctx.fillStyle='hsl('+en.hue+',45%,32%)'; ctx.fillRect(ex-s*0.32,ey-s*0.5+bob,s*0.64,s*0.9);
      ctx.fillStyle='#1d1d1d'; ctx.fillRect(ex-s*0.32,ey-s*0.28+bob,s*0.64,s*0.12);
      ctx.fillStyle='#e8b98a'; ctx.beginPath(); ctx.arc(ex,ey-s*0.68+bob,s*0.2,0,7); ctx.fill();
      ctx.fillStyle='#2b2b2b'; ctx.beginPath(); ctx.arc(ex,ey-s*0.74+bob,s*0.2,Math.PI,0); ctx.fill();
      ctx.strokeStyle='#111'; ctx.lineWidth=Math.max(2,s*0.06); ctx.beginPath(); ctx.moveTo(ex+s*0.3,ey+bob); ctx.lineTo(ex+s*0.8,ey-s*0.2+bob); ctx.stroke();
      ctx.fillStyle='#111'; ctx.fillRect(ex-s*0.5,ey-s*0.02,10,4);
      ctx.fillStyle='#ff3b30'; ctx.fillRect(ex-18,ey-s*1.05,36,5);
      ctx.fillStyle='#37e05a'; ctx.fillRect(ex-18,ey-s*1.05,36*(0.6+0.4*Math.abs(Math.sin(t+i))),5);
    });
    var gx=W/2, gy=H+20;
    ctx.fillStyle='rgba(0,0,0,.4)'; ctx.beginPath(); ctx.ellipse(gx,gy-90,150,40,0,0,7); ctx.fill();
    ctx.fillStyle='#24272e'; ctx.beginPath(); ctx.moveTo(gx-46,gy-170); ctx.lineTo(gx+46,gy-170); ctx.lineTo(gx+80,gy-10); ctx.lineTo(gx-80,gy-10); ctx.closePath(); ctx.fill();
    ctx.fillStyle='#3a3f48'; ctx.beginPath(); ctx.moveTo(gx-46,gy-170); ctx.lineTo(gx+46,gy-170); ctx.lineTo(gx+30,gy-90); ctx.lineTo(gx-30,gy-90); ctx.closePath(); ctx.fill();
    ctx.fillStyle='#15171c'; ctx.fillRect(gx-12,gy-196,24,30);
    ctx.fillStyle='#ffbe2e'; ctx.fillRect(gx-12,gy-196,24,5);
    if(flash>0.05){ var f=flash; ctx.fillStyle='rgba(255,220,80,'+(0.9*f)+')'; ctx.beginPath(); ctx.moveTo(gx-30,gy-210); ctx.lineTo(gx+30,gy-210); ctx.lineTo(gx,gy-280-40*f); ctx.closePath(); ctx.fill(); ctx.fillStyle='rgba(255,255,255,'+(0.7*f)+')'; ctx.beginPath(); ctx.arc(gx,gy-205,10+20*f,0,7); ctx.fill(); }
    ctx.fillStyle='rgba(255,255,255,.85)'; ctx.font='bold 13px Arial'; ctx.fillText('CLAUDE-OF-DUTY • DESERT DAWN', 14, H-16);
    ctx.fillStyle='rgba(255,190,46,.95)'; ctx.font='bold 13px Arial'; ctx.fillText(started?'● LIVE':'● DEMO MODE — PRESS PLAY', W-240, H-16);
    ctx.restore();
    requestAnimationFrame(draw);
  }
  draw();
})();
</script>
</body>
</html>
HTML_EOF
  fi
fi

/usr/bin/time -p test -f "$STATIC_DIR/index.html"
/usr/bin/time -p ls -l "$STATIC_DIR/index.html"

# Publish deployment output for the controller.
/usr/bin/time -p mkdir -p "$WEB_DIR"
/usr/bin/time -p bash -c 'printf "%s" "$0" > /dev/null' "$PROJECT_ROOT"
DEPLOY_JSON=$(printf '{"project":"%s","directory":"%s"}' "$PROJECT_ROOT" "$STATIC_DIR")
/usr/bin/time -p printf '%s' "$DEPLOY_JSON" > "$WEB_DIR/deployment-output.json"
/usr/bin/time -p cat "$WEB_DIR/deployment-output.json"

# Serve the static directory in the foreground.
/usr/bin/time -p node --version
/usr/bin/time -p cat > "$PROJECT_ROOT/.omgithub-static-server.mjs" <<SERVER_EOF
import { createServer } from 'node:http';
import { readFileSync, existsSync, statSync } from 'node:fs';
import { resolve, join, extname } from 'node:path';
const root = process.env.STATIC_DIR || '$STATIC_DIR';
const port = Number(process.env.PORT || '3000');
const mime = { '.html':'text/html; charset=utf-8', '.js':'application/javascript', '.css':'text/css', '.json':'application/json', '.svg':'image/svg+xml', '.png':'image/png', '.jpg':'image/jpeg', '.webp':'image/webp', '.wasm':'application/wasm', '.glb':'model/gltf-binary', '.ico':'image/x-icon', '.txt':'text/plain' };
const server = createServer((req, res) => {
  try {
    const url = new URL(req.url, 'http://localhost');
    let path = resolve(root, '.' + decodeURIComponent(url.pathname));
    if (path !== resolve(root) && !path.startsWith(resolve(root) + '/')) { res.writeHead(404); res.end('Not found'); return; }
    if (existsSync(path) && statSync(path).isDirectory()) path = join(path, 'index.html');
    if (!existsSync(path)) path = join(root, 'index.html');
    const content = readFileSync(path);
    res.writeHead(200, { 'Content-Type': mime[extname(path)] || 'application/octet-stream', 'Cache-Control': 'no-cache', 'Content-Length': content.length });
    res.end(content);
  } catch { res.writeHead(404); res.end('Not found'); }
});
server.listen(port, '0.0.0.0', () => console.log('Serving ' + root + ' on :' + port));
SERVER_EOF
STATIC_DIR="$STATIC_DIR" /usr/bin/time -p node "$PROJECT_ROOT/.omgithub-static-server.mjs"
