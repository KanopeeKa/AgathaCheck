import React, { useState } from 'react';
import {
  ArrowRight,
  ArrowUpRight,
  BadgeCheck,
  Building2,
  Check,
  Clock3,
  Eye,
  EyeOff,
  HeartHandshake,
  LockKeyhole,
  Mail,
  ShieldCheck,
  Sparkles,
  UserRound,
  UsersRound,
} from 'lucide-react';

type Mode = 'sign-in' | 'create';
type Audience = 'guardian' | 'organisation';

export default function GuardianDesk() {
  const [mode, setMode] = useState<Mode>('sign-in');
  const [audience, setAudience] = useState<Audience>('guardian');
  const [showPassword, setShowPassword] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [notice, setNotice] = useState('');

  const choosePath = (nextAudience: Audience) => {
    setAudience(nextAudience);
    setNotice(
      nextAudience === 'guardian'
        ? 'The guardian desk is ready when you are.'
        : 'Organisation access keeps every handover in view.',
    );
    window.setTimeout(() => {
      document.getElementById('guardian-access')?.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }, 40);
  };

  const switchMode = (nextMode: Mode) => {
    setMode(nextMode);
    setNotice('');
    setShowPassword(false);
  };

  const handleSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (mode === 'sign-in') {
      if (!email || !password) {
        setNotice('Add your email and password to open your desk.');
        return;
      }
      setNotice('That is a mock sign-in — your care desk would open here.');
      return;
    }
    if (!firstName || !email || !password) {
      setNotice('Add your name, email and a password to get started.');
      return;
    }
    setNotice(`Welcome, ${firstName}. Your ${audience === 'guardian' ? 'guardian' : 'organisation'} desk is ready to set up.`);
  };

  return (
    <main className="gd-shell">
      <style>{`
        .gd-shell{
          --gd-paper:#f5f2e9;
          --gd-paper-deep:#ebe9dc;
          --gd-panel:#fbfaf5;
          --gd-ink:#2f4439;
          --gd-ink-soft:#52685a;
          --gd-olive:#3b5849;
          --gd-olive-dark:#2f483d;
          --gd-sage:#a8b9a0;
          --gd-sage-soft:#dfe8d8;
          --gd-gold:#caa75c;
          --gd-gold-soft:#efe5c5;
          --gd-clay:#c47d68;
          --gd-line:#d6dfd3;
          min-height:100vh;
          background:var(--gd-paper);
          color:var(--gd-ink);
          font-family:'DM Sans',ui-sans-serif,system-ui,sans-serif;
          overflow:hidden;
        }
        .gd-shell *{box-sizing:border-box}
        .gd-shell button,.gd-shell input{font:inherit}
        .gd-frame{min-height:100vh;display:grid;grid-template-columns:minmax(0,1.05fr) minmax(430px,.95fr)}
        .gd-story{
          position:relative;
          min-height:100vh;
          padding:30px clamp(26px,5vw,76px) 34px;
          display:flex;
          flex-direction:column;
          overflow:hidden;
          background:
            radial-gradient(circle at 82% 17%,rgba(205,181,104,.18),transparent 24%),
            radial-gradient(circle at 11% 92%,rgba(164,192,159,.2),transparent 31%),
            var(--gd-olive);
          color:#f2f2e9;
        }
        .gd-story:before{
          content:'';
          position:absolute;
          width:520px;
          height:520px;
          right:-235px;
          bottom:-245px;
          border:1px solid rgba(218,224,201,.18);
          border-radius:50%;
          box-shadow:0 0 0 34px rgba(218,224,201,.045),0 0 0 68px rgba(218,224,201,.035);
          pointer-events:none;
        }
        .gd-story:after{
          content:'';
          position:absolute;
          inset:0;
          opacity:.13;
          pointer-events:none;
          background-image:radial-gradient(rgba(255,255,255,.6) .55px,transparent .7px);
          background-size:6px 6px;
          mix-blend-mode:soft-light;
        }
        .gd-story > *{position:relative;z-index:1}
        .gd-topbar{display:flex;align-items:center;justify-content:space-between;gap:18px}
        .gd-brand{display:inline-flex;align-items:center;gap:10px;color:#f4f2e8;text-decoration:none;font-weight:700;font-size:17px;letter-spacing:-.045em}
         .gd-brand-mark{width:33px;height:33px;border-radius:11px;background:var(--gd-gold);display:grid;place-items:center;overflow:hidden;box-shadow:0 5px 0 rgba(31,53,43,.14)}
         .gd-brand-mark img{width:29px;height:29px;display:block}
        .gd-top-note{display:flex;align-items:center;gap:8px;color:#cbd4c7;font-size:10px;letter-spacing:.08em;text-transform:uppercase;font-weight:700}
        .gd-top-note i{width:7px;height:7px;background:#bdce9d;border-radius:50%;box-shadow:0 0 0 4px rgba(189,206,157,.13)}
        .gd-story-copy{max-width:660px;margin:auto 0;padding:clamp(50px,8vh,100px) 0 44px}
        .gd-eyebrow{display:flex;align-items:center;gap:10px;color:#d6c481;font-size:10px;font-weight:700;letter-spacing:.18em;text-transform:uppercase}
        .gd-eyebrow:before{content:'';width:25px;height:1px;background:var(--gd-gold)}
        .gd-story h1{max-width:650px;margin:22px 0 20px;color:#f6f3e8;font-family:'Instrument Serif',Georgia,serif;font-size:clamp(49px,6.4vw,86px);font-weight:400;line-height:.96;letter-spacing:-.065em}
        .gd-story h1 em{color:#d5c47f;font-style:normal}
        .gd-lede{max-width:500px;margin:0;color:#c7d0c5;font-size:16px;line-height:1.65;letter-spacing:-.01em}
         .gd-shelter-note{display:flex;align-items:flex-start;gap:9px;max-width:500px;margin-top:16px;color:#d8dfd2;font-size:12px;line-height:1.5}
         .gd-shelter-note svg{flex:0 0 auto;margin-top:2px;color:#d6c481}
        .gd-signal-row{display:flex;flex-wrap:wrap;gap:9px;margin-top:29px}
        .gd-signal{display:inline-flex;align-items:center;gap:7px;border:1px solid rgba(225,228,202,.19);background:rgba(225,228,202,.09);border-radius:999px;padding:8px 11px;color:#e2e5d7;font-size:10px;font-weight:600}
        .gd-signal svg{color:#d6c481}
        .gd-desk-preview{max-width:570px;margin-top:45px;border:1px solid rgba(221,228,206,.22);border-radius:16px;background:rgba(18,42,31,.22);box-shadow:0 22px 44px rgba(22,39,30,.13);overflow:hidden}
        .gd-preview-top{display:flex;align-items:center;justify-content:space-between;padding:12px 15px;border-bottom:1px solid rgba(221,228,206,.15);color:#b7c7b4;font-size:9px;text-transform:uppercase;letter-spacing:.12em}
        .gd-preview-live{display:flex;align-items:center;gap:6px;color:#d7e0bd}
        .gd-preview-live:before{content:'';width:5px;height:5px;border-radius:50%;background:#c6d693}
        .gd-preview-content{display:grid;grid-template-columns:1.1fr .9fr;gap:18px;padding:16px}
        .gd-preview-heading{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:12px}
        .gd-preview-heading small{display:block;color:#aabca8;font-size:8px;text-transform:uppercase;letter-spacing:.14em;margin-bottom:5px}
        .gd-preview-heading strong{font-family:'Instrument Serif',Georgia,serif;font-size:22px;font-weight:400;color:#eff0e5;letter-spacing:-.04em}
        .gd-preview-heading span{color:#c9d19d;font-size:9px}
        .gd-preview-list{display:grid;gap:7px}
        .gd-preview-task{display:grid;grid-template-columns:35px 1fr 16px;gap:8px;align-items:center;padding:8px 9px;border-radius:9px;background:rgba(232,237,218,.09);font-size:9px;color:#d3dbcf}
        .gd-preview-task time{color:#a9bbaa;font-family:'Space Mono',monospace;font-size:8px}
        .gd-preview-task b{font-weight:600}
        .gd-preview-task small{display:block;color:#9daf9e;font-size:8px;margin-top:2px}
        .gd-preview-task svg{color:#c9d49c}
        .gd-preview-task.done{opacity:.58}
        .gd-preview-task.done b{text-decoration:line-through}
        .gd-preview-side{border-left:1px solid rgba(221,228,206,.15);padding-left:17px}
        .gd-side-label{color:#aabca8;font-size:8px;letter-spacing:.14em;text-transform:uppercase}
        .gd-side-number{margin-top:9px;color:#f0f0e5;font-family:'Instrument Serif',Georgia,serif;font-size:34px;line-height:1}
        .gd-side-number span{font-family:'DM Sans',sans-serif;color:#aabca8;font-size:10px}
        .gd-side-rule{height:5px;margin-top:14px;border-radius:10px;background:rgba(210,225,200,.17);overflow:hidden}
        .gd-side-rule i{display:block;width:82%;height:100%;background:#bdc993;border-radius:10px}
        .gd-side-caption{margin-top:8px;color:#aabca8;font-size:9px;line-height:1.4}
        .gd-story-footer{display:flex;align-items:center;gap:8px;color:#aebcac;font-size:10px}
        .gd-story-footer svg{color:#d2bf76}
        .gd-access{
          min-height:100vh;
          padding:clamp(24px,4vw,58px) clamp(22px,5vw,76px) 28px;
          display:flex;
          flex-direction:column;
          justify-content:center;
          background:var(--gd-paper);
        }
        .gd-access-inner{width:100%;max-width:430px;margin:0 auto}
        .gd-access-kicker{display:flex;align-items:center;justify-content:space-between;gap:14px;margin-bottom:20px}
        .gd-kicker-label{color:#819382;font-size:10px;font-weight:700;letter-spacing:.16em;text-transform:uppercase}
        .gd-help{display:inline-flex;align-items:center;gap:6px;color:#768879;text-decoration:none;font-size:10px;font-weight:600}
        .gd-help:hover{color:var(--gd-olive)}
        .gd-access h2{margin:0;color:var(--gd-ink);font-family:'Instrument Serif',Georgia,serif;font-size:39px;font-weight:400;line-height:1.02;letter-spacing:-.055em}
        .gd-access-intro{max-width:370px;margin:12px 0 25px;color:#748177;font-size:13px;line-height:1.55}
        .gd-audience-switch{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin-bottom:19px;padding:5px;border:1px solid var(--gd-line);border-radius:12px;background:rgba(255,255,255,.26)}
        .gd-audience-switch button{display:flex;align-items:center;justify-content:center;gap:7px;min-height:35px;border:0;border-radius:8px;background:transparent;color:#829085;font-size:10px;font-weight:700;cursor:pointer}
        .gd-audience-switch button.active{background:var(--gd-panel);color:var(--gd-olive);box-shadow:0 3px 10px rgba(58,76,61,.08)}
        .gd-auth-card{padding:24px;border:1px solid var(--gd-line);border-radius:17px;background:var(--gd-panel);box-shadow:0 14px 32px rgba(49,69,54,.075)}
        .gd-tabs{display:grid;grid-template-columns:1fr 1fr;gap:4px;margin:-4px 0 22px;border-bottom:1px solid #e0e5dc}
        .gd-tabs button{position:relative;border:0;background:transparent;color:#929d94;padding:9px 5px 12px;font-size:11px;font-weight:700;cursor:pointer}
        .gd-tabs button:after{content:'';position:absolute;left:0;right:0;bottom:-1px;height:2px;border-radius:2px;background:transparent;transform:scaleX(.65);opacity:0}
        .gd-tabs button.active{color:var(--gd-olive)}
        .gd-tabs button.active:after{background:var(--gd-gold);transform:scaleX(1);opacity:1}
        .gd-form{display:grid;gap:15px}
        .gd-form-row{display:grid;grid-template-columns:1fr 1fr;gap:10px}
        .gd-field{display:grid;gap:7px}
        .gd-field label{display:flex;align-items:center;justify-content:space-between;color:#5d7062;font-size:10px;font-weight:700}
        .gd-field label span{color:#9ba69c;font-weight:500}
        .gd-input-wrap{display:flex;align-items:center;gap:9px;height:43px;padding:0 11px;border:1px solid #d8e0d6;border-radius:9px;background:#fdfcf8}
        .gd-input-wrap:focus-within{border-color:#839c82;box-shadow:0 0 0 3px #e4ebde}
        .gd-input-wrap svg{flex:0 0 auto;color:#91a093}
        .gd-input-wrap input{width:100%;min-width:0;border:0;outline:0;background:transparent;color:var(--gd-ink);font-size:12px}
        .gd-input-wrap input::placeholder{color:#a8b2aa}
        .gd-input-action{display:grid;place-items:center;border:0;background:transparent;color:#8a998e;padding:2px;cursor:pointer}
        .gd-forgot{display:flex;justify-content:flex-end;margin:-6px 0 -1px}
        .gd-forgot button{border:0;background:transparent;color:#738b75;font-size:10px;font-weight:700;cursor:pointer;padding:2px}
        .gd-forgot button:hover{text-decoration:underline;text-underline-offset:3px}
        .gd-submit{display:flex;align-items:center;justify-content:center;gap:8px;width:100%;height:45px;border:0;border-radius:9px;background:var(--gd-olive);color:#f4f3e8;font-size:12px;font-weight:700;cursor:pointer;box-shadow:0 6px 0 #294336;transition:transform .18s ease,opacity .18s ease}
        .gd-submit:hover{transform:translateY(-2px)}
        .gd-submit:active{transform:translateY(1px)}
        .gd-form-note{min-height:15px;margin:0;color:#748476;font-size:10px;line-height:1.4}
        .gd-notice{display:flex;gap:8px;align-items:flex-start;margin:15px 0 0;padding:10px 11px;border:1px solid #dfd7ae;border-radius:9px;background:#f4edcf;color:#78683d;font-size:10px;line-height:1.4}
        .gd-notice svg{flex:0 0 auto;margin-top:1px}
        .gd-assurance{display:flex;align-items:flex-start;gap:10px;margin-top:17px;padding-top:16px;border-top:1px solid #e3e7df;color:#718074;font-size:10px;line-height:1.45}
        .gd-assurance svg{flex:0 0 auto;color:#79957e}
        .gd-assurance strong{display:block;color:#536659;font-size:10px;margin-bottom:2px}
        .gd-access-foot{display:flex;justify-content:space-between;gap:12px;margin-top:22px;color:#9aa49b;font-size:9px}
        .gd-access-foot span{display:flex;align-items:center;gap:5px}
        .gd-access-foot svg{color:#879887}
        .gd-access-foot a{color:#738775;text-decoration:none}
        .gd-access-foot a:hover{text-decoration:underline;text-underline-offset:3px}
        .gd-below{grid-column:1/-1;display:grid;grid-template-columns:1fr 1fr;background:var(--gd-paper-deep);border-top:1px solid var(--gd-line)}
        .gd-below article{padding:38px clamp(24px,6vw,90px) 42px}
        .gd-below article + article{border-left:1px solid var(--gd-line)}
        .gd-below-label{display:flex;align-items:center;gap:9px;color:#829381;font-size:9px;font-weight:700;letter-spacing:.16em;text-transform:uppercase}
        .gd-below-label svg{color:var(--gd-clay)}
        .gd-below h3{margin:12px 0 7px;color:var(--gd-ink);font-family:'Instrument Serif',Georgia,serif;font-size:28px;font-weight:400;letter-spacing:-.04em}
        .gd-below p{max-width:470px;margin:0;color:#718075;font-size:12px;line-height:1.6}
        .gd-below-link{display:inline-flex;align-items:center;gap:6px;margin-top:15px;border:0;background:transparent;color:var(--gd-olive);font-size:10px;font-weight:700;padding:0;cursor:pointer}
        .gd-below-link:hover{gap:9px}
        .gd-reveal{animation:gd-rise .6s ease both}
        .gd-reveal-delay{animation:gd-rise .6s .1s ease both}
        @keyframes gd-rise{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:translateY(0)}}
        @media(max-width:880px){
          .gd-frame{display:block}
          .gd-story{min-height:auto;padding:25px 24px 32px}
          .gd-story-copy{padding:65px 0 34px}
          .gd-story h1{max-width:600px;font-size:clamp(48px,9vw,74px)}
          .gd-desk-preview{margin-top:35px;max-width:620px}
          .gd-access{min-height:auto;padding:45px 24px 46px}
          .gd-access-inner{max-width:480px}
          .gd-below{display:block}
          .gd-below article{padding:32px 24px 35px}
          .gd-below article + article{border-left:0;border-top:1px solid var(--gd-line)}
        }
        @media(max-width:520px){
          .gd-topbar{align-items:flex-start}
          .gd-top-note{max-width:105px;text-align:right;line-height:1.25}
          .gd-story-copy{padding:58px 0 28px}
          .gd-story h1{font-size:52px}
          .gd-lede{font-size:14px;line-height:1.6}
          .gd-signal-row{gap:7px;margin-top:23px}
          .gd-signal{font-size:9px;padding:7px 9px}
          .gd-desk-preview{margin-top:28px;border-radius:13px}
          .gd-preview-content{grid-template-columns:1fr;padding:13px;gap:14px}
          .gd-preview-side{border-left:0;border-top:1px solid rgba(221,228,206,.15);padding:14px 0 0;display:grid;grid-template-columns:1fr 1fr;align-items:end}
          .gd-side-rule{margin-top:0}
          .gd-side-caption{grid-column:1/-1}
          .gd-access{padding:34px 18px 38px}
          .gd-access h2{font-size:35px}
          .gd-auth-card{padding:20px 17px}
          .gd-form-row{grid-template-columns:1fr;gap:15px}
          .gd-access-foot{flex-direction:column;align-items:flex-start}
          .gd-below article{padding:29px 20px 32px}
        }
      `}</style>

      <div className="gd-frame">
        <section className="gd-story" aria-labelledby="guardian-desk-title">
          <div className="gd-topbar gd-reveal">
            <div className="gd-brand">
              <span className="gd-brand-mark"><img src={`${import.meta.env.BASE_URL}agathatrack-care-mark.svg`} alt="" /></span>
               <span>AgathaTrack</span>
            </div>
            <div className="gd-top-note"><i /> A calmer way to coordinate care</div>
          </div>

          <div className="gd-story-copy">
            <div className="gd-eyebrow gd-reveal-delay">The guardian operations desk</div>
            <h1 className="gd-reveal">Keep care close.<br /><em>Keep everyone ready.</em></h1>
            <p className="gd-lede gd-reveal-delay">
               AgathaTrack turns the small, important details of looking after an animal into a shared view of today, what comes next, and who has it covered.
            </p>
            <p className="gd-shelter-note gd-reveal-delay">
              <Building2 size={14} />
              <span>For shelters and foster teams, every handover and next step stays close at hand.</span>
            </p>
            <div className="gd-signal-row gd-reveal-delay">
              <span className="gd-signal"><Check size={12} /> Today, at a glance</span>
              <span className="gd-signal"><UsersRound size={12} /> Clear handovers</span>
              <span className="gd-signal"><ShieldCheck size={12} /> Private by design</span>
            </div>

            <div className="gd-desk-preview gd-reveal-delay" aria-label="Preview of the Guardian Operations Desk">
              <div className="gd-preview-top">
                <span>Guardian Operations Desk</span>
                <span className="gd-preview-live">Synced just now</span>
              </div>
              <div className="gd-preview-content">
                <div>
                  <div className="gd-preview-heading">
                    <div><small>Tuesday · 14 May</small><strong>Today for Miso</strong></div>
                    <span>2 of 4 done</span>
                  </div>
                  <div className="gd-preview-list">
                    <div className="gd-preview-task done"><time>08:00</time><div><b>Breakfast + probiotic</b><small>1 scoop · with food</small></div><Check size={13} /></div>
                    <div className="gd-preview-task"><time>12:30</time><div><b>Midday water check</b><small>Target 220 ml</small></div><Clock3 size={13} /></div>
                    <div className="gd-preview-task"><time>17:45</time><div><b>Evening walk</b><small>20–30 minutes · gentle pace</small></div><Clock3 size={13} /></div>
                  </div>
                </div>
                <div className="gd-preview-side">
                  <div><div className="gd-side-label">Wellness signal</div><div className="gd-side-number">82 <span>/ 100</span></div></div>
                  <div className="gd-side-rule"><i /></div>
                  <div className="gd-side-caption">Steady this week<br />No handoffs waiting</div>
                </div>
              </div>
            </div>
          </div>

          <div className="gd-story-footer"><HeartHandshake size={15} /> Built for the people who notice everything.</div>
        </section>

        <section className="gd-access" id="guardian-access" aria-label="Account access">
          <div className="gd-access-inner">
            <div className="gd-access-kicker">
              <span className="gd-kicker-label">Open your care desk</span>
              <a className="gd-help" href="#how-it-works"><Sparkles size={12} /> How it works <ArrowUpRight size={12} /></a>
            </div>
            <h2>{mode === 'sign-in' ? 'Welcome back, guardian.' : 'Start with what matters.'}</h2>
            <p className="gd-access-intro">
              {mode === 'sign-in'
                ? 'Pick up the care plan where you left it. Your people, your notes, and the next right thing are waiting.'
                : 'Make everyday care easier to share. Set up your desk in a few minutes, then invite the people you trust.'}
            </p>

            <div className="gd-audience-switch" aria-label="Choose your AgathaTrack space">
              <button className={audience === 'guardian' ? 'active' : ''} onClick={() => setAudience('guardian')} type="button">
                  <HeartHandshake size={14} /> Pet guardian
              </button>
              <button className={audience === 'organisation' ? 'active' : ''} onClick={() => setAudience('organisation')} type="button">
                <Building2 size={14} /> Organisation
              </button>
            </div>

            <div className="gd-auth-card">
              <div className="gd-tabs" role="tablist" aria-label="Account action">
                <button className={mode === 'sign-in' ? 'active' : ''} onClick={() => switchMode('sign-in')} type="button" role="tab" aria-selected={mode === 'sign-in'}>Sign in</button>
                <button className={mode === 'create' ? 'active' : ''} onClick={() => switchMode('create')} type="button" role="tab" aria-selected={mode === 'create'}>Create account</button>
              </div>

              <form className="gd-form" onSubmit={handleSubmit}>
                {mode === 'create' && (
                  <div className="gd-form-row">
                    <label className="gd-field">
                      <span>First name</span>
                      <div className="gd-input-wrap"><UserRound size={15} /><input value={firstName} onChange={(event) => setFirstName(event.target.value)} placeholder="Jordan" autoComplete="given-name" /></div>
                    </label>
                    <label className="gd-field">
                      <span>Last name <span>Optional</span></span>
                      <div className="gd-input-wrap"><UserRound size={15} /><input value={lastName} onChange={(event) => setLastName(event.target.value)} placeholder="Miller" autoComplete="family-name" /></div>
                    </label>
                  </div>
                )}

                <label className="gd-field">
                  <span>Email address</span>
                  <div className="gd-input-wrap"><Mail size={15} /><input value={email} onChange={(event) => setEmail(event.target.value)} type="email" placeholder="you@example.com" autoComplete="email" required /></div>
                </label>

                <label className="gd-field">
                  <span>Password {mode === 'create' && <span>6+ characters</span>}</span>
                  <div className="gd-input-wrap">
                    <LockKeyhole size={15} />
                    <input value={password} onChange={(event) => setPassword(event.target.value)} type={showPassword ? 'text' : 'password'} placeholder={mode === 'create' ? 'Choose a password' : 'Your password'} autoComplete={mode === 'create' ? 'new-password' : 'current-password'} required />
                    <button className="gd-input-action" type="button" aria-label={showPassword ? 'Hide password' : 'Show password'} onClick={() => setShowPassword((visible) => !visible)}>{showPassword ? <EyeOff size={15} /> : <Eye size={15} />}</button>
                  </div>
                </label>

                {mode === 'sign-in' && (
                  <div className="gd-forgot"><button type="button" onClick={() => setNotice('A reset link would be sent to your email address.')}>Forgot password?</button></div>
                )}

                <p className="gd-form-note">{mode === 'create' ? 'By creating an account, you agree to our terms and privacy notice.' : 'Use the email connected to your care desk.'}</p>
                <button className="gd-submit" type="submit">
                  {mode === 'sign-in' ? <>Sign in to desk <ArrowRight size={15} /></> : <>Create my desk <ArrowRight size={15} /></>}
                </button>
              </form>

              {notice && <div className="gd-notice" role="status"><BadgeCheck size={14} /> <span>{notice}</span></div>}
              <div className="gd-assurance">
                <ShieldCheck size={17} />
                <div><strong>Your care details stay yours.</strong> AgathaTrack is designed for trusted circles, with clear access and no noise.</div>
              </div>
            </div>

            <div className="gd-access-foot">
              <span><LockKeyhole size={11} /> Secure access for care teams</span>
              <span><a href="#privacy">Privacy</a><span>·</span><a href="#terms">Terms</a></span>
            </div>
          </div>
        </section>

        <section className="gd-below" id="how-it-works">
          <article>
            <div className="gd-below-label"><HeartHandshake size={13} /> For pet guardians</div>
            <h3>One home for the little things.</h3>
            <p>Keep feeding notes, medication, appointments, and the things only you know in one place — ready for a partner, sitter, or family member to pick up.</p>
            <button className="gd-below-link" onClick={() => choosePath('guardian')} type="button">Open the guardian path <ArrowRight size={13} /></button>
          </article>
          <article>
            <div className="gd-below-label"><Building2 size={13} /> For organisations</div>
            <h3>Handover without the guesswork.</h3>
            <p>Give teams and trusted partners a shared view of responsibility, so the right person sees the right detail before care changes hands.</p>
            <button className="gd-below-link" onClick={() => choosePath('organisation')} type="button">Explore organisation access <ArrowRight size={13} /></button>
          </article>
        </section>
      </div>
    </main>
  );
}