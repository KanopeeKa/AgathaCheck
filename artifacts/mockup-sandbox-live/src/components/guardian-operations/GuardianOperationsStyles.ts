// ─── Palette tokens (mirrors AppColorTokens) ────────────────────────────────
// guardianCarePrimary  = olive green – for guardian-care emphasis
// organizationOchre    = golden ochre – ONLY as org-context reserve
export const C = {
  // surfaces
  bg: '#f1f3ee',
  surface: '#fbfcf8',
  surfaceVariant: '#eef0e9',

  // primary (olive guardian-care)
  primary: '#5e7c65',           // guardianCarePrimary
  primaryContainer: '#dde9de',  // guardianCareLight
  onPrimaryContainer: '#2e5233', // guardianCareActive
  onPrimary: '#ffffff',

  // secondary (org ochre – reserve only)
  secondary: '#8b7226',         // organizationOchre
  secondaryContainer: '#f3e7c3', // organizationOchreLight
  onSecondaryContainer: '#3e3000',

  // neutrals
  outline: '#c5cec4',
  outlineVariant: '#dce4da',
  onSurface: '#1c2720',
  onSurfaceVariant: '#6b7a6e',

  // top-app-bar background
  topBar: '#f7f9f5',

  // overdue / due status (semantic, not warning)
  overdueBg: '#fdf2ee',
  overdueText: '#8b3a2b',
  dueBg: '#eef4ee',
  dueText: '#2e5233',

  // vet mark (org ochre accent)
  vetMark: '#f3e7c3',
  vetMarkText: '#7a6320',

  // toast
  toastBg: '#2e3d33',
} as const;

export function buildStyles(): string {
  return `
    /* ── Reset & root ── */
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    .fr-root {
      min-height: 100vh;
      background: ${C.bg};
      color: ${C.onSurface};
      font-family: system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;
      font-size: 14px;
      display: flex;
      flex-direction: column;
      position: relative;
    }

    /* ── Top app bar (M3 compact) ── */
    .fr-topbar {
      height: 64px;
      background: ${C.topBar};
      border-bottom: 1px solid ${C.outlineVariant};
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 16px;
      gap: 8px;
      position: sticky;
      top: 0;
      z-index: 10;
    }
    .fr-topbar-left { display: flex; align-items: center; gap: 8px; }
    .fr-topbar-icon {
      width: 48px; height: 48px;
      display: grid; place-items: center;
      background: none; border: none;
      color: ${C.onSurface}; cursor: pointer;
      border-radius: 50%;
      transition: background 0.15s;
    }
    .fr-topbar-icon:hover, .fr-topbar-icon:focus-visible {
      background: rgba(30,50,35,0.08);
      outline: none;
    }
    .fr-topbar-icon:focus-visible { outline: 2px solid ${C.primary}; outline-offset: 2px; }
    .fr-brand-mark {
      width: 32px; height: 32px;
      border-radius: 10px;
      background: ${C.primary};
      color: ${C.onPrimary};
      display: grid; place-items: center;
    }
    .fr-topbar-title {
      font-size: 22px;
      font-weight: 400;
      letter-spacing: 0;
      color: ${C.onSurface};
    }
    .fr-topbar-right { display: flex; align-items: center; gap: 4px; }
    .fr-nav-badge {
      position: relative;
    }
    .fr-nav-badge::after {
      content: '';
      position: absolute;
      top: 10px; right: 10px;
      width: 8px; height: 8px;
      border-radius: 50%;
      background: ${C.secondary};
      border: 2px solid ${C.topBar};
    }
    .fr-avatar-btn {
      width: 36px; height: 36px;
      border-radius: 50%;
      background: ${C.primary};
      color: ${C.onPrimary};
      border: none; cursor: pointer;
      font-size: 11px; font-weight: 700;
      display: grid; place-items: center;
      letter-spacing: .04em;
    }
    .fr-avatar-btn:focus-visible { outline: 2px solid ${C.primary}; outline-offset: 2px; }

    /* ── Navigation drawer (mobile overlay) ── */
    .fr-drawer-overlay {
      position: fixed; inset: 0; background: rgba(0,0,0,.32); z-index: 20;
      animation: fr-fade-in 0.18s ease;
    }
    .fr-drawer {
      position: fixed; top: 0; left: 0; bottom: 0;
      width: 280px; background: #2e3e35;
      color: #edf0e8; padding: 0; z-index: 21;
      display: flex; flex-direction: column;
      animation: fr-slide-in 0.22s cubic-bezier(.32,.75,.5,1);
    }
    @keyframes fr-fade-in { from { opacity: 0 } to { opacity: 1 } }
    @keyframes fr-slide-in { from { transform: translateX(-100%) } to { transform: translateX(0) } }
    .fr-drawer-header {
      height: 64px; display: flex; align-items: center; gap: 12px; padding: 0 16px;
      border-bottom: 1px solid rgba(255,255,255,.08);
    }
    .fr-drawer-mark {
      width: 32px; height: 32px; border-radius: 10px;
      background: ${C.secondary}; color: ${C.onSecondaryContainer};
      display: grid; place-items: center;
    }
    .fr-drawer-app { font-size: 16px; font-weight: 600; letter-spacing: -.01em; }
    .fr-drawer-close {
      margin-left: auto; width: 40px; height: 40px;
      background: none; border: none; color: #c0c9c0; cursor: pointer;
      border-radius: 50%; display: grid; place-items: center;
    }
    .fr-drawer-section { padding: 12px 12px 4px; font-size: 11px; letter-spacing: .12em; text-transform: uppercase; color: #8e9e90; }
    .fr-drawer-nav {
      display: flex; align-items: center; gap: 12px;
      width: 100%; border: none; background: transparent;
      color: #c0c9c0; padding: 14px 16px; border-radius: 28px;
      text-align: left; font: 500 14px system-ui; cursor: pointer;
      margin: 1px 8px; width: calc(100% - 16px);
      transition: background 0.14s;
    }
    .fr-drawer-nav:hover { background: rgba(255,255,255,.06); }
    .fr-drawer-nav.active { background: ${C.primaryContainer}; color: ${C.onPrimaryContainer}; font-weight: 600; }
    .fr-drawer-nav.active svg { color: ${C.primary}; }
    .fr-drawer-foot {
      margin-top: auto; padding: 16px; border-top: 1px solid rgba(255,255,255,.08);
      display: flex; align-items: center; gap: 12px;
    }
    .fr-drawer-foot-name { font-size: 13px; font-weight: 600; }
    .fr-drawer-foot-role { font-size: 11px; color: #8e9e90; margin-top: 2px; }

    /* ── Scrollable content ── */
    .fr-scroll {
      flex: 1; overflow-y: auto;
      padding: 16px;
      display: flex; justify-content: center;
    }
    .fr-content {
      width: 100%; max-width: 1180px;
    }

    /* ── Welcome row ── */
    .fr-welcome {
      display: flex; align-items: flex-end; justify-content: space-between;
      gap: 12px; margin-bottom: 16px; flex-wrap: wrap;
    }
    .fr-welcome-kicker {
      font-size: 11px; font-weight: 700; letter-spacing: .12em;
      text-transform: uppercase; color: ${C.onSurfaceVariant}; margin-bottom: 6px;
    }
    .fr-welcome-h1 {
      font-size: clamp(24px, 3.5vw, 36px);
      font-weight: 400; letter-spacing: -.03em;
      color: ${C.onSurface}; line-height: 1.08;
    }
    .fr-welcome-h1 em { font-style: normal; color: ${C.primary}; }
    .fr-welcome-meta { font-size: 12px; color: ${C.onSurfaceVariant}; text-align: right; }
    .fr-welcome-meta b { display: block; color: ${C.onSurface}; font-weight: 600; font-size: 13px; }

    /* ── Section cards (M3 geometry) ── */
    .fr-card {
      background: ${C.surface};
      border: 1px solid ${C.outlineVariant};
      border-radius: 20px;
      padding: 20px 20px 6px;
      margin-bottom: 0;
    }
    .fr-card-primary {
      background: ${C.primaryContainer};
      border-color: ${C.outline};
    }

    /* ── Layout: pets top, secondary sections below ── */
    .fr-layout {
      display: flex; flex-direction: column; gap: 16px;
    }
    .fr-secondary {
      display: flex; flex-direction: column; gap: 16px;
    }
    @media (min-width: 900px) {
      .fr-secondary { flex-direction: row; }
      .fr-secondary > * { flex: 1; min-width: 0; }
    }

    /* ── Section header ── */
    .fr-section-head {
      display: flex; align-items: center; justify-content: space-between;
      margin-bottom: 10px;
    }
    .fr-section-title {
      font-size: 16px; font-weight: 600; letter-spacing: -.01em;
      color: ${C.onSurface};
    }
    .fr-section-sub {
      font-size: 12px; color: ${C.onSurfaceVariant};
      margin-bottom: 12px; margin-top: -6px;
    }

    /* ── Text button (M3 TextButton) ── */
    .fr-text-btn {
      display: inline-flex; align-items: center; gap: 2px;
      min-height: 48px; min-width: 48px; padding: 0 4px;
      background: none; border: none;
      color: ${C.primary}; font: 600 13px system-ui; cursor: pointer;
      border-radius: 8px;
      transition: background 0.15s;
    }
    .fr-text-btn:hover, .fr-text-btn:focus-visible {
      background: ${C.primaryContainer};
      outline: none;
    }
    .fr-text-btn:focus-visible { outline: 2px solid ${C.primary}; outline-offset: 1px; }
    .fr-chevron { flex-shrink: 0; }

    /* ── Subgroup title ── */
    .fr-subgroup-title {
      font-size: 12px; font-weight: 600; letter-spacing: .01em;
      color: ${C.onSurfaceVariant}; padding-bottom: 8px;
    }

    /* ── Pet chip strip ── */
    .fr-pet-strip {
      display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 12px;
    }
    .fr-pet-chip {
      display: flex; align-items: center; gap: 10px;
      min-height: 48px; padding: 8px 14px 8px 8px;
      background: ${C.surface}; border: 1px solid ${C.outlineVariant};
      border-radius: 14px; cursor: pointer; text-align: left;
      font: 500 13px system-ui; color: ${C.onSurface};
      transition: background 0.14s, border-color 0.14s;
    }
    .fr-pet-chip:hover { background: ${C.surfaceVariant}; }
    .fr-pet-chip.active {
      background: ${C.surface};
      border-color: ${C.primary};
      box-shadow: 0 0 0 2px ${C.primary}22;
    }
    .fr-pet-chip:focus-visible { outline: 2px solid ${C.primary}; outline-offset: 2px; }
    .fr-pet-chip b { display: block; font-size: 13px; font-weight: 600; }
    .fr-pet-chip small { display: block; font-size: 11px; color: ${C.onSurfaceVariant}; margin-top: 2px; }

    .fr-pet-avatar {
      width: 36px; height: 36px; border-radius: 12px;
      display: grid; place-items: center;
      color: #fff; font-size: 10px; font-weight: 700; letter-spacing: .04em;
      flex-shrink: 0;
    }
    .fr-pet-avatar.lg {
      width: 52px; height: 52px; border-radius: 16px; font-size: 14px;
    }

    /* ── Pet detail card ── */
    .fr-pet-detail {
      background: ${C.surface};
      border: 1px solid ${C.outlineVariant};
      border-radius: 16px;
      padding: 16px;
      margin-bottom: 14px;
      position: relative;
    }
    .fr-pet-detail-head {
      display: flex; align-items: flex-start; gap: 14px; margin-bottom: 14px;
    }
    .fr-pet-detail-name { font-size: 20px; font-weight: 600; letter-spacing: -.03em; }
    .fr-pet-detail-meta { font-size: 12px; color: ${C.onSurfaceVariant}; margin-top: 3px; }
    .fr-pet-detail-status { font-size: 12px; margin-top: 4px; }
    .fr-close-btn {
      margin-left: auto; width: 40px; height: 40px;
      border: none; background: none; cursor: pointer;
      color: ${C.onSurfaceVariant}; border-radius: 50%;
      display: grid; place-items: center;
      flex-shrink: 0;
      transition: background 0.14s;
    }
    .fr-close-btn:hover { background: ${C.surfaceVariant}; }
    .fr-close-btn:focus-visible { outline: 2px solid ${C.primary}; outline-offset: 2px; }

    .fr-wellness-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
    .fr-label-tiny { font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: .1em; color: ${C.onSurfaceVariant}; margin-bottom: 4px; }
    .fr-wellness-score { font-size: 30px; font-weight: 700; letter-spacing: -.05em; color: ${C.onSurface}; }
    .fr-wellness-score small { font-size: 13px; color: ${C.onSurfaceVariant}; font-weight: 400; letter-spacing: 0; }

    .fr-ring {
      width: 64px; height: 64px; border-radius: 50%;
      background: conic-gradient(${C.primary} 0 82%, ${C.outlineVariant} 82%);
      display: grid; place-items: center; position: relative;
    }
    .fr-ring::after {
      content: ''; position: absolute; inset: 7px;
      border-radius: 50%; background: ${C.surface};
    }
    .fr-ring-inner {
      position: relative; z-index: 1;
      font-size: 12px; font-weight: 700; color: ${C.primary};
    }
    .fr-wellness-bar {
      height: 4px; border-radius: 8px; background: ${C.outlineVariant}; overflow: hidden;
    }
    .fr-wellness-bar-fill { height: 100%; background: ${C.primary}; border-radius: 8px; transition: width 0.5s ease; }

    /* ── Due & Overdue event rows ── */
    .fr-event-row {
      display: grid;
      grid-template-columns: 68px 1fr 44px;
      align-items: center; gap: 10px;
      border-top: 1px solid ${C.outlineVariant};
      padding: 12px 0;
    }
    .fr-event-row.done strong { text-decoration: line-through; color: ${C.onSurfaceVariant}; }
    .fr-event-body strong { display: block; font-size: 13px; font-weight: 600; color: ${C.onSurface}; }
    .fr-event-body span { display: block; font-size: 11px; color: ${C.onSurfaceVariant}; margin-top: 2px; }

    .fr-badge {
      display: inline-block; padding: 4px 6px;
      border-radius: 6px; font-size: 9px; font-weight: 700;
      letter-spacing: .08em; text-transform: uppercase;
      white-space: nowrap;
    }
    .fr-badge.overdue { background: ${C.overdueBg}; color: ${C.overdueText}; }
    .fr-badge.due     { background: ${C.dueBg};     color: ${C.dueText}; }
    .fr-badge.visit   { background: ${C.secondaryContainer}; color: ${C.secondary}; }

    .fr-check-btn {
      width: 44px; height: 44px;
      border: 1px solid ${C.outlineVariant};
      border-radius: 12px; background: ${C.surface};
      color: transparent; display: grid; place-items: center;
      cursor: pointer; flex-shrink: 0;
      transition: background 0.14s, border-color 0.14s;
    }
    .fr-check-btn.checked { background: ${C.primary}; border-color: ${C.primary}; color: #fff; }
    .fr-check-btn:focus-visible { outline: 2px solid ${C.primary}; outline-offset: 2px; }

    /* ── Composer ── */
    .fr-add-btn {
      display: flex; align-items: center; gap: 6px;
      width: calc(100% - 0px); margin: 8px 0;
      min-height: 48px; padding: 0 16px;
      border: 1px dashed ${C.outline};
      border-radius: 12px; background: transparent;
      color: ${C.onSurfaceVariant}; font: 500 13px system-ui; cursor: pointer;
      transition: background 0.14s;
    }
    .fr-add-btn:hover { background: ${C.primaryContainer}; }
    .fr-add-btn:focus-visible { outline: 2px solid ${C.primary}; outline-offset: 2px; }
    .fr-add-icon { color: ${C.primary}; flex-shrink: 0; }

    .fr-composer {
      display: flex; gap: 8px; align-items: center;
      border-top: 1px solid ${C.outlineVariant}; padding: 10px 0 4px;
      margin-top: 4px;
    }
    .fr-composer-input {
      flex: 1; min-width: 0;
      height: 44px; padding: 0 12px;
      border: 1px solid ${C.outline}; border-radius: 12px;
      background: ${C.surface}; font: 13px system-ui;
      color: ${C.onSurface}; outline: none;
    }
    .fr-composer-input:focus { border-color: ${C.primary}; box-shadow: 0 0 0 2px ${C.primary}22; }
    .fr-composer-add {
      height: 44px; padding: 0 16px;
      background: ${C.primary}; color: #fff;
      border: none; border-radius: 12px;
      font: 600 13px system-ui; cursor: pointer;
    }
    .fr-composer-cancel {
      width: 44px; height: 44px;
      background: ${C.surfaceVariant}; color: ${C.onSurfaceVariant};
      border: none; border-radius: 12px; cursor: pointer;
      display: grid; place-items: center;
    }

    /* ── Vet rows ── */
    .fr-vet-row {
      display: grid;
      grid-template-columns: 44px 1fr 44px;
      align-items: center; gap: 12px;
      border-top: 1px solid ${C.outlineVariant};
      padding: 12px 0;
    }
    .fr-vet-mark {
      width: 44px; height: 44px;
      border-radius: 14px;
      background: ${C.vetMark}; color: ${C.vetMarkText};
      font: 700 11px system-ui; letter-spacing: .04em;
      display: grid; place-items: center;
      border: none; cursor: pointer;
      transition: opacity 0.14s;
    }
    .fr-vet-mark:hover { opacity: .8; }
    .fr-vet-mark:focus-visible { outline: 2px solid ${C.secondary}; outline-offset: 2px; }
    .fr-vet-body strong { display: block; font-size: 13px; font-weight: 600; color: ${C.onSurface}; }
    .fr-vet-body span { display: block; font-size: 11px; color: ${C.onSurfaceVariant}; margin-top: 2px; }
    .fr-vet-action {
      width: 44px; height: 44px;
      border-radius: 12px;
      background: ${C.primaryContainer}; color: ${C.primary};
      border: none; cursor: pointer;
      display: grid; place-items: center;
      transition: background 0.14s;
    }
    .fr-vet-action:hover { background: ${C.outline}; }
    .fr-vet-action:focus-visible { outline: 2px solid ${C.primary}; outline-offset: 2px; }

    /* ── Toast ── */
    .fr-toast {
      position: fixed; bottom: 20px; left: 50%;
      transform: translateX(-50%);
      background: ${C.toastBg}; color: #fff;
      padding: 11px 16px; border-radius: 12px;
      font-size: 12px; font-weight: 500;
      display: flex; align-items: center; gap: 8px;
      z-index: 100; pointer-events: none;
      white-space: nowrap;
      box-shadow: 0 6px 20px rgba(0,0,0,.25);
      animation: fr-toast-in 0.2s ease;
    }
    @keyframes fr-toast-in { from { opacity: 0; transform: translateX(-50%) translateY(8px); } to { opacity: 1; transform: translateX(-50%) translateY(0); } }

    /* ── Responsive ── */
    @media (max-width: 480px) {
      .fr-welcome-meta { display: none; }
      .fr-event-row { grid-template-columns: 60px 1fr 44px; }
    }
  `;
}
