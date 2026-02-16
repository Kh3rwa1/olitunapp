// PWA Install Prompt Handler
let deferredPrompt;

window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault();
    deferredPrompt = e;
    showInstallBanner();
});

function showInstallBanner() {
    // Don't show if already dismissed
    if (localStorage.getItem('pwa_install_dismissed')) return;

    const banner = document.createElement('div');
    banner.id = 'pwa-install-banner';
    banner.innerHTML = `
    <div style="
      position:fixed;bottom:0;left:0;right:0;z-index:99999;
      background:linear-gradient(135deg,#059669,#10B981);
      color:#fff;padding:16px 20px;
      display:flex;align-items:center;justify-content:space-between;
      font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;
      box-shadow:0 -4px 20px rgba(0,0,0,0.3);
    ">
      <div style="display:flex;align-items:center;gap:12px;">
        <img src="icons/Icon-192.png" width="40" height="40" style="border-radius:10px;">
        <div>
          <div style="font-weight:700;font-size:15px;">Install Olitun</div>
          <div style="font-size:12px;opacity:0.85;">Learn Ol Chiki offline</div>
        </div>
      </div>
      <div style="display:flex;gap:8px;">
        <button onclick="dismissInstall()" style="
          background:rgba(255,255,255,0.2);border:none;color:#fff;
          padding:8px 14px;border-radius:8px;cursor:pointer;font-size:13px;
        ">Later</button>
        <button onclick="triggerInstall()" style="
          background:#fff;border:none;color:#059669;
          padding:8px 16px;border-radius:8px;cursor:pointer;font-weight:700;font-size:13px;
        ">Install</button>
      </div>
    </div>
  `;
    document.body.appendChild(banner);
}

function triggerInstall() {
    if (deferredPrompt) {
        deferredPrompt.prompt();
        deferredPrompt.userChoice.then((result) => {
            deferredPrompt = null;
            removeBanner();
        });
    }
}

function dismissInstall() {
    localStorage.setItem('pwa_install_dismissed', '1');
    removeBanner();
}

function removeBanner() {
    const banner = document.getElementById('pwa-install-banner');
    if (banner) banner.remove();
}

// iOS Safari "Add to Home Screen" guidance
window.addEventListener('load', () => {
    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
    const isStandalone = window.navigator.standalone;
    if (isIOS && !isStandalone && !localStorage.getItem('pwa_install_dismissed')) {
        setTimeout(() => {
            const tip = document.createElement('div');
            tip.id = 'pwa-install-banner';
            tip.innerHTML = `
        <div style="
          position:fixed;bottom:0;left:0;right:0;z-index:99999;
          background:#1F2937;color:#fff;padding:16px 20px;
          text-align:center;font-family:-apple-system,sans-serif;
          font-size:14px;box-shadow:0 -4px 20px rgba(0,0,0,0.3);
        ">
          <span>Install Olitun: tap <strong>Share</strong> → <strong>Add to Home Screen</strong></span>
          <button onclick="dismissInstall()" style="
            margin-left:12px;background:rgba(255,255,255,0.15);
            border:none;color:#fff;padding:6px 12px;border-radius:6px;
            cursor:pointer;font-size:12px;
          ">✕</button>
        </div>
      `;
            document.body.appendChild(tip);
        }, 3000);
    }
});

// Track successful install
window.addEventListener('appinstalled', () => {
    localStorage.setItem('pwa_installed', '1');
    removeBanner();
});
