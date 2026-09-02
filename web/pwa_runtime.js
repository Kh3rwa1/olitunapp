// Runtime boot helpers externalized from index.html so they comply with the
// strict `script-src` CSP (no inline scripts). Loaded with `defer`.
(function() {
  'use strict';

  // Remove loading indicator cleanly when Flutter first frame renders
  window.addEventListener('flutter-first-frame', function() {
    var loader = document.getElementById('loading-indicator');
    if (loader) {
      loader.style.opacity = '0';
      setTimeout(function() { loader.remove(); }, 350);
    }
  });

  // Safety fallback: if app takes >8s to boot, show reload button
  setTimeout(function() {
    var reloadBtn = document.getElementById('loading-reload-btn');
    if (reloadBtn && document.getElementById('loading-indicator')) {
      reloadBtn.style.display = 'inline-block';
      reloadBtn.addEventListener('click', function() {
        window.location.reload();
      });
    }
  }, 8000);

  // Live Offline / Online Detection
  function updateOnlineStatus() {
    var indicator = document.getElementById('offline-indicator');
    if (!indicator) return;
    if (navigator.onLine === false) {
      indicator.style.display = 'flex';
    } else {
      indicator.style.display = 'none';
    }
  }
  window.addEventListener('offline', updateOnlineStatus);
  window.addEventListener('online', updateOnlineStatus);
  if (!navigator.onLine) updateOnlineStatus();

  // Service Worker Update Listener
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.addEventListener('controllerchange', function() {
      // Automatically reload when new service worker takes control if requested
    });

    navigator.serviceWorker.ready.then(function(registration) {
      registration.addEventListener('updatefound', function() {
        var newWorker = registration.installing;
        if (!newWorker) return;
        newWorker.addEventListener('statechange', function() {
          if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
            var updateToast = document.getElementById('pwa-update-toast');
            var updateBtn = document.getElementById('pwa-update-btn');
            if (updateToast && updateBtn) {
              updateToast.style.display = 'flex';
              updateBtn.onclick = function() {
                newWorker.postMessage({ action: 'skipWaiting' });
                window.location.reload();
              };
            }
          }
        });
      });
    });
  }
})();
