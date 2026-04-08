// PWA Install Prompt Handler
let deferredPrompt;

window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault();
    deferredPrompt = e;
    showInstallBanner();
});

function baseBannerStyle() {
    return 'position:fixed;bottom:0;left:0;right:0;z-index:99999;padding:16px 20px;font-family:-apple-system,BlinkMacSystemFont,\'Segoe UI\',sans-serif;box-shadow:0 -4px 20px rgba(0,0,0,0.3);';
}

function showInstallBanner() {
    if (localStorage.getItem('pwa_install_dismissed')) return;

    const banner = document.createElement('div');
    banner.id = 'pwa-install-banner';

    const wrapper = document.createElement('div');
    wrapper.style.cssText = `${baseBannerStyle()}background:linear-gradient(135deg,#059669,#10B981);color:#fff;display:flex;align-items:center;justify-content:space-between;`;

    const left = document.createElement('div');
    left.style.cssText = 'display:flex;align-items:center;gap:12px;';

    const icon = document.createElement('img');
    icon.src = 'icons/Icon-192.png';
    icon.width = 40;
    icon.height = 40;
    icon.style.borderRadius = '10px';

    const textWrap = document.createElement('div');
    const title = document.createElement('div');
    title.style.cssText = 'font-weight:700;font-size:15px;';
    title.textContent = 'Install Olitun';
    const subtitle = document.createElement('div');
    subtitle.style.cssText = 'font-size:12px;opacity:0.85;';
    subtitle.textContent = 'Learn Ol Chiki offline';
    textWrap.append(title, subtitle);
    left.append(icon, textWrap);

    const actions = document.createElement('div');
    actions.style.cssText = 'display:flex;gap:8px;';

    const laterBtn = document.createElement('button');
    laterBtn.type = 'button';
    laterBtn.style.cssText = 'background:rgba(255,255,255,0.2);border:none;color:#fff;padding:8px 14px;border-radius:8px;cursor:pointer;font-size:13px;';
    laterBtn.textContent = 'Later';
    laterBtn.addEventListener('click', dismissInstall);

    const installBtn = document.createElement('button');
    installBtn.type = 'button';
    installBtn.style.cssText = 'background:#fff;border:none;color:#059669;padding:8px 16px;border-radius:8px;cursor:pointer;font-weight:700;font-size:13px;';
    installBtn.textContent = 'Install';
    installBtn.addEventListener('click', triggerInstall);

    actions.append(laterBtn, installBtn);
    wrapper.append(left, actions);
    banner.appendChild(wrapper);
    document.body.appendChild(banner);
}

function triggerInstall() {
    if (deferredPrompt) {
        deferredPrompt.prompt();
        deferredPrompt.userChoice.then(() => {
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

window.addEventListener('load', () => {
    const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
    const isStandalone = window.navigator.standalone;
    if (isIOS && !isStandalone && !localStorage.getItem('pwa_install_dismissed')) {
        setTimeout(() => {
            const tip = document.createElement('div');
            tip.id = 'pwa-install-banner';

            const wrapper = document.createElement('div');
            wrapper.style.cssText = `${baseBannerStyle()}background:#1F2937;color:#fff;text-align:center;font-size:14px;`;

            const msg = document.createElement('span');
            msg.textContent = 'Install Olitun: tap Share → Add to Home Screen';

            const close = document.createElement('button');
            close.type = 'button';
            close.style.cssText = 'margin-left:12px;background:rgba(255,255,255,0.15);border:none;color:#fff;padding:6px 12px;border-radius:6px;cursor:pointer;font-size:12px;';
            close.textContent = '✕';
            close.addEventListener('click', dismissInstall);

            wrapper.append(msg, close);
            tip.appendChild(wrapper);
            document.body.appendChild(tip);
        }, 3000);
    }
});

window.addEventListener('appinstalled', () => {
    localStorage.setItem('pwa_installed', '1');
    removeBanner();
});
