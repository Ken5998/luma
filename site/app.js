const canvas = document.querySelector('#light');
const ctx = canvas.getContext('2d');
const colors = {Aurora:['#51dbba','#9171ec','#ee85ba'],Original:['#8b98f0','#dd8ab2','#e8ba7f'],Plasma:['#f05f41','#efa242','#973c6a'],Poolside:['#529fcc','#99d8e8','#69d8ca'],Freedom:['#0057b7','#167dd9','#ffd700']};
let palette='Aurora', time=0, previous=0, raf=0, width=600, height=540;
const reduced = matchMedia('(prefers-reduced-motion: reduce)');
let paused = reduced.matches;
function render(){
 ctx.fillStyle='#090b16';ctx.fillRect(0,0,width,height);
 const glow=ctx.createRadialGradient(width*.55,height*.5,10,width*.5,height*.5,width*.7);glow.addColorStop(0,'#222136');glow.addColorStop(1,'#090b16');ctx.fillStyle=glow;ctx.fillRect(0,0,width,height);
 ctx.globalCompositeOperation='screen';
 for(let i=0;i<330;i++){
  const lane=i/330; const phase=lane*Math.PI*5+time*.13;
  const y=height*(lane*1.25-.12); const wave=Math.sin(phase);
  const x=width*(.49+.33*Math.sin(lane*4.8+time*.1));
  const len=25+55*(.5+.5*Math.sin(i*9.2));
  ctx.strokeStyle=colors[palette][i%3];ctx.globalAlpha=.13+.5*(.5+.5*Math.sin(i*1.6));ctx.lineWidth=1+1.5*(.5+.5*Math.sin(i*3));
  ctx.beginPath();ctx.moveTo(x+Math.sin(i*2)*width*.28,y);ctx.bezierCurveTo(x+wave*len,y-len*.4,x+wave*len*1.8,y-len*.7,x+wave*len*2,y-len);ctx.stroke();
 }
 ctx.globalAlpha=1;ctx.globalCompositeOperation='source-over';
}
function resize(){const rect=canvas.getBoundingClientRect();width=rect.width;height=rect.height;const dpr=Math.min(devicePixelRatio||1,2);canvas.width=Math.round(width*dpr);canvas.height=Math.round(height*dpr);ctx.setTransform(dpr,0,0,dpr,0,0);render();}
function tick(timestamp){raf=0;if(paused||document.hidden)return;time+=Math.min((timestamp-previous)/1000,.05);previous=timestamp;render();raf=requestAnimationFrame(tick);}
function animate(){cancelAnimationFrame(raf);raf=0;previous=performance.now();if(!paused&&!document.hidden)raf=requestAnimationFrame(tick);}
const motion=document.querySelector('#motion');function updateMotion(){motion.textContent=paused?'Play animation':'Pause animation';motion.setAttribute('aria-pressed',String(paused));animate();}
motion.addEventListener('click',()=>{paused=!paused;updateMotion();});
reduced.addEventListener('change',()=>{paused=reduced.matches;updateMotion();});
document.addEventListener('visibilitychange',animate);
document.querySelectorAll('[data-palette]').forEach(button=>button.addEventListener('click',()=>{palette=button.dataset.palette;document.querySelectorAll('[data-palette]').forEach(b=>{const selected=b===button;b.classList.toggle('selected',selected);b.setAttribute('aria-pressed',String(selected));});document.querySelector('#palette-name').textContent=`${String(Object.keys(colors).indexOf(palette)+1).padStart(2,'0')} / ${palette.toUpperCase()}`;render();}));
const clock=document.querySelector('#clock');function updateClock(){clock.textContent=new Intl.DateTimeFormat(undefined,{hour:'2-digit',minute:'2-digit',hourCycle:'h23'}).format(new Date());}
document.querySelector('#clock-toggle').addEventListener('change',event=>{clock.hidden=!event.target.checked;updateClock();});
setInterval(updateClock,1000);new ResizeObserver(resize).observe(canvas);resize();updateMotion();
