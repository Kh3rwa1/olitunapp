// Olitun AAA+ PWA Install & Lifecycle Handler
let deferredPrompt = null;
const SNOOZE_DAYS = 7;
const SNOOZE_MS = SNOOZE_DAYS * 24 * 60 * 60 * 1000;

window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault();
    deferredPrompt = e;
    window.dispatchEvent(new CustomEvent('pwa-installable'));
    if (!isSnoozed() && !isStandalonePwa()) {
        showInstallBanner();
    }
});

function baseBannerStyle() {
    return 'position:fixed;bottom:max(16px, env(safe-area-inset-bottom));left:16px;right:16px;max-width:540px;margin:0 auto;z-index:99999;font-family:-apple-system,BlinkMacSystemFont,\'Segoe UI\',Roboto,sans-serif;box-shadow:0 20px 50px rgba(0,0,0,0.35);border-radius:20px;overflow:hidden;animation:pwaSlideUp 0.35s cubic-bezier(0.16, 1, 0.3, 1);';
}

function isSnoozed() {
    const dismissedAt = localStorage.getItem('pwa_install_dismissed_at');
    if (!dismissedAt) return false;
    const elapsed = Date.now() - parseInt(dismissedAt, 10);
    return elapsed < SNOOZE_MS;
}

function showInstallBanner() {
    if (document.getElementById('pwa-install-banner')) return;

    const banner = document.createElement('div');
    banner.id = 'pwa-install-banner';
    banner.setAttribute('role', 'dialog');
    banner.setAttribute('aria-modal', 'false');
    banner.setAttribute('aria-label', 'Install Olitun App');

    const styleTag = document.createElement('style');
    styleTag.textContent = `
      @keyframes pwaSlideUp {
        from { opacity: 0; transform: translateY(24px) scale(0.96); }
        to { opacity: 1; transform: translateY(0) scale(1); }
      }
    `;
    banner.appendChild(styleTag);

    const wrapper = document.createElement('div');
    wrapper.style.cssText = `${baseBannerStyle()}background:linear-gradient(135deg,#064E3B 0%,#047857 50%,#10B981 100%);color:#FFFFFF;padding:16px 20px;border:1px solid rgba(255,255,255,0.18);`;

    const contentRow = document.createElement('div');
    contentRow.style.cssText = 'display:flex;align-items:center;justify-content:space-between;gap:16px;flex-wrap:wrap;';

    const left = document.createElement('div');
    left.style.cssText = 'display:flex;align-items:center;gap:14px;min-width:200px;flex:1;';

    const icon = document.createElement('img');
    icon.src = 'icons/Icon-192.png';
    icon.alt = 'Olitun App Icon';
    icon.width = 44;
    icon.height = 44;
    icon.style.cssText = 'border-radius:12px;box-shadow:0 4px 14px rgba(0,0,0,0.25);flex-shrink:0;';

    const textWrap = document.createElement('div');
    const title = document.createElement('div');
    title.style.cssText = 'font-weight:800;font-size:15px;line-height:1.2;';
    title.textContent = 'Install Olitun';
    const subtitle = document.createElement('div');
    subtitle.style.cssText = 'font-size:12px;opacity:0.9;margin-top:3px;';
    subtitle.textContent = 'Learn Ol Chiki with offline lessons & audio';
    textWrap.append(title, subtitle);
    left.append(icon, textWrap);

    const actions = document.createElement('div');
    actions.style.cssText = 'display:flex;align-items:center;gap:10px;margin-left:auto;';

    const laterBtn = document.createElement('button');
    laterBtn.type = 'button';
    laterBtn.style.cssText = 'min-height:44px;background:rgba(255,255,255,0.18);border:1px solid rgba(255,255,255,0.25);color:#FFFFFF;padding:8px 16px;border-radius:12px;cursor:pointer;font-size:13px;font-weight:600;transition:background 0.2s;';
    laterBtn.setAttribute('aria-label', 'Dismiss install prompt');
    laterBtn.textContent = 'Later';
    laterBtn.addEventListener('click', dismissInstall);

    const installBtn = document.createElement('button');
    installBtn.type = 'button';
    installBtn.style.cssText = 'min-height:44px;background:#FFFFFF;border:none;color:#064E3B;padding:8px 20px;border-radius:12px;cursor:pointer;font-weight:800;font-size:13px;box-shadow:0 4px 14px rgba(0,0,0,0.2);transition:transform 0.1s;';
    installBtn.setAttribute('aria-label', 'Install Olitun as an application');
    installBtn.textContent = 'Install App';
    installBtn.addEventListener('click', triggerInstall);

    actions.append(laterBtn, installBtn);
    contentRow.append(left, actions);
    wrapper.appendChild(contentRow);
    banner.appendChild(wrapper);
    document.body.appendChild(banner);

    // Close on Escape key
    window.addEventListener('keydown', onKeyDown);
}

function onKeyDown(e) {
    if (e.key === 'Escape') {
        dismissInstall();
    }
}

function triggerInstall() {
    if (deferredPrompt) {
        deferredPrompt.prompt();
        deferredPrompt.userChoice.then((choiceResult) => {
            if (choiceResult.outcome === 'accepted') {
                window.dispatchEvent(new CustomEvent('pwa-installed'));
            }
            deferredPrompt = null;
            removeBanner();
        });
    }
}

function dismissInstall() {
    localStorage.setItem('pwa_install_dismissed_at', Date.now().toString());
    window.dispatchEvent(new CustomEvent('pwa-dismissed'));
    removeBanner();
}

function removeBanner() {
    window.removeEventListener('keydown', onKeyDown);
    const banner = document.getElementById('pwa-install-banner');
    if (banner) banner.remove();
}

// iOS Safari Smart Add-To-Home-Screen Banner
window.addEventListener('load', () => {
    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;
    const isSafari = /Safari/.test(navigator.userAgent) && !/CriOS|FxiOS|EdgiOS/.test(navigator.userAgent);
    const isStandalone = isStandalonePwa();

    if (isIOS && isSafari && !isStandalone && !isSnoozed()) {
        setTimeout(() => {
            if (document.getElementById('pwa-install-banner')) return;

            const tip = document.createElement('div');
            tip.id = 'pwa-install-banner';
            tip.setAttribute('role', 'dialog');
            tip.setAttribute('aria-label', 'Install Olitun on iOS');

            const wrapper = document.createElement('div');
            wrapper.style.cssText = `${baseBannerStyle()}background:#111827;color:#FFFFFF;border:1px solid #374151;padding:14px 18px;display:flex;align-items:center;justify-content:space-between;gap:12px;`;

            const text = document.createElement('div');
            text.style.cssText = 'font-size:13px;font-weight:600;line-height:1.4;';
            text.innerHTML = 'Install <strong>Olitun</strong>: Tap <span style="font-size:15px;">⎋</span> Share then <strong>Add to Home Screen ＋</strong>';

            const close = document.createElement('button');
            close.type = 'button';
            close.style.cssText = 'min-height:44px;background:rgba(255,255,255,0.12);border:1px solid rgba(255,255,255,0.18);color:#FFFFFF;padding:6px 14px;border-radius:10px;cursor:pointer;font-size:12px;font-weight:700;flex-shrink:0;';
            close.setAttribute('aria-label', 'Dismiss iOS install tip');
            close.textContent = 'Got it';
            close.addEventListener('click', dismissInstall);

            wrapper.append(text, close);
            tip.appendChild(wrapper);
            document.body.appendChild(tip);
        }, 3500);
    }
});

window.addEventListener('appinstalled', () => {
    localStorage.setItem('pwa_installed', '1');
    window.dispatchEvent(new CustomEvent('pwa-installed'));
    removeBanner();
});

function isStandalonePwa() {
    return window.matchMedia('(display-mode: standalone)').matches ||
           window.matchMedia('(display-mode: window-controls-overlay)').matches ||
           window.navigator.standalone === true ||
           document.referrer.includes('android-app://');
}

