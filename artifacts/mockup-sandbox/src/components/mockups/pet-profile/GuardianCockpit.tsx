import React, { useState } from 'react';
import {
  Activity,
  Bell,
  CalendarDays,
  Check,
  ChevronDown,
  ChevronRight,
  Droplets,
  HeartPulse,
  Home,
  Menu,
  MoreHorizontal,
  PawPrint,
  Pill,
  Plus,
  Settings2,
  ShieldCheck,
  Sparkles,
  Stethoscope,
  X,
} from 'lucide-react';

type Task = { id: number; time: string; title: string; detail: string; kind: 'medicine' | 'care' | 'walk'; done: boolean };

const initialTasks: Task[] = [
  { id: 1, time: '08:00', title: 'Breakfast + probiotic', detail: '1 scoop · with food', kind: 'medicine', done: true },
  { id: 2, time: '12:30', title: 'Midday water check', detail: 'Target 220 ml', kind: 'care', done: false },
  { id: 3, time: '17:45', title: 'Evening walk', detail: '20–30 minutes · gentle pace', kind: 'walk', done: false },
  { id: 4, time: '21:00', title: 'Joint supplement', detail: '1 chew · after dinner', kind: 'medicine', done: false },
];

const petData = [
  { name: 'Miso', species: 'Shiba Inu · 4 yr', initials: 'MI', tone: '#D6A08F', status: 'Doing well' },
  { name: 'Basil', species: 'Tabby cat · 2 yr', initials: 'BA', tone: '#8AA59B', status: 'All caught up' },
];

function IconTile({ kind }: { kind: Task['kind'] }) {
  const Icon = kind === 'medicine' ? Pill : kind === 'walk' ? Activity : Droplets;
  return <span className={`gc-icon gc-${kind}`}><Icon size={17} strokeWidth={1.8} /></span>;
}

export default function GuardianCockpit() {
  const [activePet, setActivePet] = useState(0);
  const [tasks, setTasks] = useState(initialTasks);
  const [tab, setTab] = useState('Today');
  const [showPetMenu, setShowPetMenu] = useState(false);
  const [showComposer, setShowComposer] = useState(false);
  const [notice, setNotice] = useState('');
  const pet = petData[activePet];
  const completed = tasks.filter((task) => task.done).length;

  const toast = (message: string) => {
    setNotice(message);
    window.setTimeout(() => setNotice(''), 2400);
  };

  const toggleTask = (id: number) => {
    setTasks((current) => current.map((task) => task.id === id ? { ...task, done: !task.done } : task));
  };

  return (
    <main className="gc-shell">
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=Fraunces:opsz,wght@9..144,500&display=swap');
        .gc-shell { min-height:100vh; background:#f7f4f0; color:#2d3338; font-family:'DM Sans',sans-serif; display:flex; }
        .gc-sidebar { width:226px; flex:0 0 226px; background:#332a31; color:#f6f1ec; padding:25px 16px 20px; display:flex; flex-direction:column; }
        .gc-brand { display:flex; align-items:center; gap:10px; padding:0 10px 32px; font-weight:700; letter-spacing:-.03em; }
        .gc-brand-mark { width:30px;height:30px;border-radius:10px;background:#d6a08f;display:grid;place-items:center;color:#332a31; }
        .gc-nav-label { color:#a99ca3; font-size:10px; letter-spacing:.14em; text-transform:uppercase; margin:8px 12px 10px; }
        .gc-nav { display:flex; align-items:center; gap:11px; width:100%; border:0; background:none; color:#bdafb6; padding:11px 12px; border-radius:11px; text-align:left; font:500 13px 'DM Sans'; cursor:pointer; }
        .gc-nav.active { color:#fff; background:#54444f; }
        .gc-nav:hover { background:#453740; color:#fff; }
        .gc-sidebar-foot { margin-top:auto; border-top:1px solid #4b3c45; padding-top:18px; }
        .gc-main { min-width:0; flex:1; }
        .gc-topbar { height:78px; background:#fbf9f6; border-bottom:1px solid #e7dfd8; display:flex; align-items:center; justify-content:space-between; padding:0 clamp(20px,4vw,56px); }
        .gc-menu { display:none; border:0;background:none;color:#332a31; }
        .gc-crumb { font-size:12px; color:#8b8582; display:flex; gap:8px; align-items:center; }
        .gc-crumb strong { color:#3d363a; font-weight:600; }
        .gc-top-actions { display:flex; gap:12px; align-items:center; }
        .gc-icon-button { width:38px;height:38px;border:1px solid #e1d9d1;background:#fff;border-radius:11px;display:grid;place-items:center;color:#71676c;cursor:pointer; }
        .gc-avatar { width:37px;height:37px;border-radius:50%;display:grid;place-items:center;color:#fff;font-size:11px;font-weight:700; }
        .gc-content { max-width:1120px; margin:0 auto; padding:43px clamp(20px,4vw,56px) 60px; }
        .gc-welcome { display:flex; align-items:flex-end; justify-content:space-between; gap:20px; margin-bottom:32px; }
        .gc-eyebrow { color:#967c86; text-transform:uppercase; letter-spacing:.15em; font-size:10px; font-weight:700; margin-bottom:10px; }
        .gc-h1 { font-size:clamp(28px,4vw,40px);line-height:1.05;letter-spacing:-.055em;margin:0;color:#312a30; }
        .gc-h1 em { font-family:Fraunces,serif;font-weight:500;color:#755b68;font-style:normal; }
        .gc-date { color:#817a77;font-size:13px;text-align:right;line-height:1.5; }
        .gc-date b { color:#473d43; display:block; font-size:14px; }
        .gc-grid { display:grid; grid-template-columns:minmax(0,1.45fr) minmax(260px,.8fr); gap:22px; }
        .gc-card { background:#fffdfa;border:1px solid #e8e0d8;border-radius:18px;box-shadow:0 8px 24px rgba(71,53,44,.045); }
        .gc-hero { padding:24px; background:#f1e8e1; border-color:#e6d7cf; position:relative; overflow:hidden; }
        .gc-hero:after { content:'';position:absolute;right:-55px;top:-75px;width:220px;height:220px;border-radius:50%;border:1px solid rgba(117,91,104,.15);box-shadow:0 0 0 22px rgba(117,91,104,.04),0 0 0 44px rgba(117,91,104,.03); }
        .gc-pet-select { position:relative;z-index:2;display:flex;align-items:center;justify-content:space-between; }
        .gc-pet-button { display:flex;align-items:center;gap:12px;background:none;border:0;padding:0;cursor:pointer;color:#342c31;text-align:left; }
        .gc-pet-photo { width:54px;height:54px;border-radius:17px;display:grid;place-items:center;color:#fff;font-weight:700;letter-spacing:.06em;box-shadow:inset 0 0 0 4px rgba(255,255,255,.3); }
        .gc-pet-name { font-weight:700;font-size:20px;letter-spacing:-.04em;display:block; }
        .gc-pet-meta { color:#816e73;font-size:12px;display:block;margin-top:2px; }
        .gc-pet-menu { position:absolute;right:24px;top:84px;background:#fffdfa;border:1px solid #e4d8d1;border-radius:12px;padding:5px;box-shadow:0 12px 30px #574a421a;z-index:5;min-width:150px; }
        .gc-pet-menu button { width:100%;border:0;background:none;padding:9px;text-align:left;border-radius:8px;color:#554a50;cursor:pointer;font:500 12px 'DM Sans'; }
        .gc-pet-menu button:hover { background:#f4ebe6; }
        .gc-health { margin-top:27px;display:flex;align-items:flex-end;justify-content:space-between;position:relative;z-index:1; }
        .gc-health-label { color:#866f73;font-size:12px;margin-bottom:7px; }
        .gc-health-score { font-size:37px;letter-spacing:-.06em;font-weight:700;color:#3b3038; }
        .gc-health-score small { font-size:14px;color:#8d797c;font-weight:500;letter-spacing:0; }
        .gc-ring { width:91px;height:91px;border-radius:50%;display:grid;place-items:center;background:conic-gradient(#755b68 0 82%, #dfcfc7 82% 100%); position:relative; }
        .gc-ring:after { content:'';position:absolute;inset:8px;background:#f1e8e1;border-radius:50%; }
        .gc-ring span { position:relative;z-index:1;font-size:18px;font-weight:700;color:#624b57; }
        .gc-progress { height:5px;background:#dfd1ca;border-radius:9px;margin-top:17px;overflow:hidden;position:relative;z-index:1; }
        .gc-progress i { display:block;width:82%;height:100%;background:#755b68;border-radius:9px; }
        .gc-card-head { display:flex;align-items:center;justify-content:space-between;padding:21px 23px 14px; }
        .gc-card-title { font-size:15px;font-weight:700;letter-spacing:-.02em; }
        .gc-card-link { color:#755b68;border:0;background:none;font:600 11px 'DM Sans';cursor:pointer; }
        .gc-tasks { padding:0 12px 10px; }
        .gc-task { display:grid;grid-template-columns:50px 35px 1fr 28px;align-items:center;gap:10px;padding:13px 11px;border-top:1px solid #eee8e3; }
        .gc-task-time { font-size:11px;color:#948a85;font-variant-numeric:tabular-nums; }
        .gc-icon { width:33px;height:33px;border-radius:10px;display:grid;place-items:center; }
        .gc-medicine { background:#f3e6e2;color:#b06f69; } .gc-care { background:#e4f0eb;color:#438d74; } .gc-walk { background:#e7edf4;color:#62809e; }
        .gc-task-title { font-size:13px;font-weight:600;color:#42393e;display:block; }
        .gc-task-detail { font-size:11px;color:#9a918e;margin-top:3px;display:block; }
        .gc-task.is-done .gc-task-title { text-decoration:line-through;color:#aaa19d; }
        .gc-check { width:23px;height:23px;border:1px solid #d8cec7;border-radius:50%;background:#fff;display:grid;place-items:center;color:transparent;cursor:pointer; }
        .gc-check.checked { background:#438d74;border-color:#438d74;color:#fff; }
        .gc-stat-card { padding:22px 23px; }
        .gc-stat-row { display:flex;justify-content:space-between;align-items:center; }
        .gc-stat-main { font-size:30px;font-weight:700;letter-spacing:-.05em;color:#3b3038; }
        .gc-stat-main small { font-size:12px;font-weight:500;color:#978c87;letter-spacing:0; }
        .gc-stat-note { font-size:11px;color:#8f8580;margin-top:5px; }
        .gc-stat-icon { width:37px;height:37px;border-radius:12px;background:#e8f2ee;color:#438d74;display:grid;place-items:center; }
        .gc-mini-chart { display:flex;align-items:flex-end;gap:7px;height:53px;margin-top:22px; }
        .gc-mini-chart i { flex:1;background:#c9ddd4;border-radius:5px 5px 2px 2px;min-height:15px; } .gc-mini-chart i:nth-child(4),.gc-mini-chart i:last-child { background:#438d74; }
        .gc-side-stack { display:flex;flex-direction:column;gap:22px; }
        .gc-next { padding:22px 23px; }
        .gc-next-box { background:#f5efe9;border-radius:12px;padding:14px;margin-top:14px;display:flex;gap:11px;align-items:center; }
        .gc-next-box strong { font-size:12px;display:block; } .gc-next-box span { font-size:11px;color:#918580;display:block;margin-top:3px; }
        .gc-add { width:100%;border:1px dashed #cdbdb5;border-radius:11px;background:#fbf7f3;color:#755b68;font:600 12px 'DM Sans';padding:12px;cursor:pointer;margin-top:12px; }
        .gc-composer { border-top:1px solid #ebe2dc;padding:14px 12px;display:flex;gap:8px;align-items:center; } .gc-composer input { flex:1;border:1px solid #ded3cc;border-radius:9px;padding:10px;font:12px 'DM Sans';outline:none; } .gc-composer button { border:0;border-radius:9px;background:#755b68;color:#fff;padding:10px 14px;font:600 12px 'DM Sans';cursor:pointer; }
        .gc-toast { position:fixed;bottom:22px;left:50%;transform:translateX(-50%);background:#332a31;color:#fff;padding:11px 15px;border-radius:10px;font-size:12px;box-shadow:0 8px 22px #332a3133;z-index:20; }
        @media (max-width: 800px) { .gc-sidebar { display:none; } .gc-menu { display:block; } .gc-grid { grid-template-columns:1fr; } .gc-welcome { align-items:flex-start; flex-direction:column; } .gc-date { text-align:left; } .gc-content { padding-top:28px; } }
        @media (max-width: 480px) { .gc-topbar { height:65px; } .gc-crumb { display:none; } .gc-task { grid-template-columns:43px 32px 1fr 25px;gap:7px;padding-left:4px;padding-right:4px; } .gc-hero { padding:19px; } }
      `}</style>

      <aside className="gc-sidebar">
        <div className="gc-brand"><span className="gc-brand-mark"><PawPrint size={17} /></span><span>AgathaTrack</span></div>
        <div className="gc-nav-label">Workspace</div>
        {[
          ['Today', Home], ['Health log', HeartPulse], ['Appointments', CalendarDays], ['Pet profiles', PawPrint],
        ].map(([label, NavIcon]) => (
          <button key={label as string} className={`gc-nav ${tab === label ? 'active' : ''}`} onClick={() => { setTab(label as string); toast(`${label} view selected`); }}>
            <NavIcon size={17} strokeWidth={1.8} />{label as string}
          </button>
        ))}
        <div className="gc-nav-label" style={{ marginTop: 27 }}>Account</div>
        <button className="gc-nav" onClick={() => toast('Settings are ready to personalize')}><Settings2 size={17} strokeWidth={1.8} />Settings</button>
        <div className="gc-sidebar-foot">
          <div style={{display:'flex',alignItems:'center',gap:10,padding:'0 9px'}}>
            <div className="gc-avatar" style={{background:'#8d6d7f'}}>JM</div>
            <div><div style={{fontSize:12,fontWeight:600}}>Jordan Miller</div><div style={{fontSize:10,color:'#a99ca3',marginTop:2}}>Guardian account</div></div>
          </div>
        </div>
      </aside>

      <section className="gc-main">
        <header className="gc-topbar">
          <button className="gc-menu" onClick={() => toast('Navigation menu')}><Menu size={21}/></button>
          <div className="gc-crumb"><span>Workspace</span><ChevronRight size={13}/><strong>{tab}</strong></div>
          <div className="gc-top-actions">
            <button className="gc-icon-button" onClick={() => toast('No new notifications')}><Bell size={17}/></button>
            <button className="gc-avatar" style={{background:'#8d6d7f',border:0,cursor:'pointer'}} onClick={() => toast('Profile menu opened')}>JM</button>
          </div>
        </header>

        <div className="gc-content">
          <div className="gc-welcome">
            <div><div className="gc-eyebrow">Tuesday · 14 May 2024</div><h1 className="gc-h1">Good morning, <em>Jordan.</em></h1></div>
            <div className="gc-date"><b>One small check-in at a time.</b> Miso's daily care plan</div>
          </div>

          <div className="gc-grid">
            <div style={{display:'flex',flexDirection:'column',gap:22}}>
              <article className="gc-card gc-hero">
                <div className="gc-pet-select">
                  <button className="gc-pet-button" onClick={() => setShowPetMenu(!showPetMenu)}>
                    <span className="gc-pet-photo" style={{background:pet.tone}}>{pet.initials}</span>
                    <span><span className="gc-pet-name">{pet.name} <ChevronDown size={15} style={{verticalAlign:'-2px'}}/></span><span className="gc-pet-meta">{pet.species} · <span style={{color:'#438d74'}}>● {pet.status}</span></span></span>
                  </button>
                  <button className="gc-icon-button" style={{background:'#f8eee9',borderColor:'#ead8ce'}} onClick={() => toast('Pet profile opened')}><MoreHorizontal size={18}/></button>
                </div>
                {showPetMenu && <div className="gc-pet-menu">{petData.map((p, i) => <button key={p.name} onClick={() => {setActivePet(i);setShowPetMenu(false);toast(`${p.name}'s dashboard selected`);}}>{p.name} <span style={{color:'#a29690'}}>· {p.species.split(' · ')[0]}</span></button>)}</div>}
                <div className="gc-health"><div><div className="gc-health-label">Weekly wellness</div><div className="gc-health-score">82 <small>/ 100</small></div><div style={{fontSize:11,color:'#806e70',marginTop:4}}>Looking steady this week</div></div><div className="gc-ring"><span>82%</span></div></div>
                <div className="gc-progress"><i /></div>
              </article>

              <article className="gc-card">
                <div className="gc-card-head"><div><div className="gc-eyebrow" style={{marginBottom:5}}>Daily plan</div><div className="gc-card-title">{completed} of {tasks.length} check-ins complete</div></div><button className="gc-card-link" onClick={() => toast('Showing full health log')}>View log <ChevronRight size={12} style={{verticalAlign:'-2px'}}/></button></div>
                <div className="gc-tasks">{tasks.map((task) => <div className={`gc-task ${task.done ? 'is-done' : ''}`} key={task.id}><span className="gc-task-time">{task.time}</span><IconTile kind={task.kind}/><span><span className="gc-task-title">{task.title}</span><span className="gc-task-detail">{task.detail}</span></span><button className={`gc-check ${task.done ? 'checked' : ''}`} onClick={() => { toggleTask(task.id); toast(task.done ? 'Check-in reopened' : 'Check-in recorded'); }} aria-label={`Mark ${task.title} ${task.done ? 'incomplete' : 'complete'}`}>{task.done && <Check size={14}/>}</button></div>)}</div>
                {showComposer ? <div className="gc-composer"><input autoFocus placeholder="e.g. Nail trim at 18:00" onKeyDown={(e) => { if (e.key === 'Enter') { setShowComposer(false); toast('Care note added'); }}}/><button onClick={() => {setShowComposer(false);toast('Care note added');}}>Add</button><button onClick={() => setShowComposer(false)} style={{background:'#eee6e1',color:'#725d65',padding:'10px'}}><X size={14}/></button></div> : <div style={{padding:'0 23px 19px'}}><button className="gc-add" onClick={() => setShowComposer(true)}><Plus size={14} style={{verticalAlign:'-3px',marginRight:5}}/> Add a care note</button></div>}
              </article>
            </div>

            <div className="gc-side-stack">
              <article className="gc-card gc-stat-card"><div className="gc-stat-row"><div><div className="gc-eyebrow" style={{marginBottom:8}}>Hydration · today</div><div className="gc-stat-main">620 <small>/ 800 ml</small></div><div className="gc-stat-note">78% of daily target</div></div><span className="gc-stat-icon"><Droplets size={18}/></span></div><div className="gc-mini-chart">{[34,48,28,62,48,72].map((h,i)=><i key={i} style={{height:`${h}%`}} />)}</div><div style={{fontSize:10,color:'#9b908b',display:'flex',justifyContent:'space-between',marginTop:7}}><span>6 am</span><span>now</span></div></article>
              <article className="gc-card gc-next"><div className="gc-card-head" style={{padding:0}}><div><div className="gc-eyebrow" style={{marginBottom:5}}>Next appointment</div><div className="gc-card-title">Annual wellness exam</div></div><Stethoscope size={20} color="#755b68"/></div><div className="gc-next-box"><CalendarDays size={17} color="#755b68"/><div><strong>Thursday, 23 May</strong><span>10:30 · Cedar Grove Vet</span></div></div><button className="gc-add" onClick={() => toast('Appointment details opened')}>View appointment <ChevronRight size={13} style={{verticalAlign:'-2px'}}/></button></article>
              <article className="gc-card" style={{padding:'20px 22px',background:'#eaf3ef',borderColor:'#d7e6df'}}><div style={{display:'flex',gap:11,alignItems:'flex-start'}}><ShieldCheck size={20} color="#438d74"/><div><div style={{fontSize:13,fontWeight:700,color:'#355c4e'}}>Everything looks on track</div><div style={{fontSize:11,color:'#6e8a7e',lineHeight:1.5,marginTop:5}}>Miso's routine is 3 days stronger than last week.</div></div></div></article>
            </div>
          </div>
        </div>
      </section>
      {notice && <div className="gc-toast"><Sparkles size={13} style={{verticalAlign:'-2px',marginRight:7,color:'#d6a08f'}}/>{notice}</div>}
    </main>
  );
}