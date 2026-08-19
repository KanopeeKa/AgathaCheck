import React, { useState } from 'react';
import {
  Bell,
  CalendarDays,
  Clock3,
  HeartPulse,
  Home,
  Menu,
  PawPrint,
  Settings2,
  ShieldCheck,
  X,
} from 'lucide-react';
import { C, buildStyles } from '../../guardian-operations/GuardianOperationsStyles';
import {
  DueAndOverdueSection,
  MyPetsSection,
  MyVetsSection,
} from '../../guardian-operations/GuardianOperationsSections';

// ─── Shell + layout ───────────────────────────────────────────────────────────

export default function GuardianOperationsFlutterReady() {
  const [menuOpen, setMenuOpen] = useState(false);
  const [activeNav, setActiveNav] = useState('Home');
  const [toast, setToast] = useState('');

  const showToast = (msg: string) => {
    setToast(msg);
    window.setTimeout(() => setToast(''), 2400);
  };

  const navItems: [string, typeof Home][] = [
    ['Home', Home],
    ['Health log', HeartPulse],
    ['Appointments', CalendarDays],
    ['Pet profiles', PawPrint],
  ];

  return (
    <div className="fr-root">
      <style>{buildStyles()}</style>

      {/* Top App Bar */}
      <header className="fr-topbar">
        <div className="fr-topbar-left">
          <button
            className="fr-topbar-icon"
            onClick={() => setMenuOpen(true)}
            aria-label="Open navigation menu"
          >
            <Menu size={24} />
          </button>
          <div className="fr-brand-mark" aria-hidden="true">
            <PawPrint size={17} />
          </div>
          <span className="fr-topbar-title">AgathaTrack</span>
        </div>
        <div className="fr-topbar-right">
          <button
            className="fr-topbar-icon fr-nav-badge"
            onClick={() => showToast('No new notifications')}
            aria-label="Notifications"
          >
            <Bell size={22} />
          </button>
          <button
            className="fr-avatar-btn"
            onClick={() => showToast('Profile menu opened')}
            aria-label="Open profile menu"
          >
            JM
          </button>
        </div>
      </header>

      {/* Navigation drawer */}
      {menuOpen && (
        <>
          <div className="fr-drawer-overlay" onClick={() => setMenuOpen(false)} />
          <nav className="fr-drawer" aria-label="Main navigation">
            <div className="fr-drawer-header">
              <div className="fr-drawer-mark"><PawPrint size={16} /></div>
              <span className="fr-drawer-app">AgathaTrack</span>
              <button className="fr-drawer-close" onClick={() => setMenuOpen(false)} aria-label="Close navigation">
                <X size={20} />
              </button>
            </div>
            <div className="fr-drawer-section">Guardian desk</div>
            {navItems.map(([label, Icon]) => (
              <button
                key={label}
                className={`fr-drawer-nav ${activeNav === label ? 'active' : ''}`}
                onClick={() => { setActiveNav(label); setMenuOpen(false); showToast(`${label} selected`); }}
              >
                <Icon size={20} strokeWidth={1.8} />
                {label}
              </button>
            ))}
            <div className="fr-drawer-section" style={{ marginTop: 12 }}>Account</div>
            <button className="fr-drawer-nav" onClick={() => { setMenuOpen(false); showToast('Settings opened'); }}>
              <Settings2 size={20} strokeWidth={1.8} />
              Settings
            </button>
            <div className="fr-drawer-foot">
              <div className="fr-pet-avatar" style={{ background: C.primary, width: 40, height: 40, borderRadius: '50%' }}>JM</div>
              <div>
                <div className="fr-drawer-foot-name">Jordan Miller</div>
                <div className="fr-drawer-foot-role">Guardian account</div>
              </div>
            </div>
          </nav>
        </>
      )}

      {/* Scrollable main content */}
      <main className="fr-scroll">
        <div className="fr-content">

          {/* Welcome row */}
          <div className="fr-welcome">
            <div>
              <div className="fr-welcome-kicker">
                <ShieldCheck size={11} style={{ verticalAlign: '-1px', marginRight: 4, color: C.primary }} />
                Tuesday · 14 May 2024 · Guardian view
              </div>
              <h1 className="fr-welcome-h1">Good morning, <em>Jordan.</em></h1>
            </div>
            <div className="fr-welcome-meta">
              <b>3 items to review</b>
              Miso's care plan · last synced 09:42
            </div>
          </div>

          {/* Three sections */}
          <div className="fr-layout">
            {/* My Pets — emphasized primary card */}
            <MyPetsSection onToast={showToast} />

            {/* Secondary: Due & Overdue + My Vets (side-by-side on wide) */}
            <div className="fr-secondary">
              <DueAndOverdueSection onToast={showToast} />
              <MyVetsSection onToast={showToast} />
            </div>
          </div>

        </div>
      </main>

      {/* Toast */}
      {toast && (
        <div className="fr-toast" role="status" aria-live="polite">
          <Clock3 size={13} style={{ color: C.secondary, flexShrink: 0 }} />
          {toast}
        </div>
      )}
    </div>
  );
}
